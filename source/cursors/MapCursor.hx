package cursors;

import cursors.AnchoredSprite;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import inputHandlers.ActionInputHandler;
import inputHandlers.MoveInputHandler;
import observerPattern.eventSystem.EventTypes;
import utilities.HideableEntity;
import observerPattern.Observed;
import observerPattern.Subject;
import utilities.UpdatingEntity;

/**
 * The cursor that the player moves around the map to direct their characters.
 * 	
 * 	General execution follows this pattern of logic:
 * 		- Performs any required asset/variable initialization.
 * 		- Creates all sets of corners needed.
 * 		- Calls a "movement mode" function to set up the corners.
 * 		- Waits for and responds to user input to determine where to move.
 * 
 * 	Movement mode functions follow this pattern of logic:
 * 		- Clear out the tweens carrying out the old movement function.
 * 		- Change the anchor offsets tracked by the map cursor to match the new 
 * 			movement function's offsets.
 * 		- Adjust the anchor values of the corners by the difference between
 * 			their old anchor coordinates and the new ones. For example, if the old anchor
 * 			offset for the top left corner was -5 and the new offset is -3, the corner's
 * 			anchor coordinates would be increased by 2.
 * 		- Create a new set of tweens that dictate how the corners should move about
 * 			their new anchor coordinates.
 * 
 * 	Cursor movement follows this pattern of logic:
 * 		- Calculate the cursor's real position in the scene by multiplying its logical
 * 			position (measured in rows and columns) by the tile size.
 * 		- Add the cursor-tracked top & left anchor offsets to the cursor's real position
 * 			to determine where the top left corner's anchor's expected position.
 * 		- If the top left corner's vertical or horizontal anchor coordinates do
 *			not match the expected position, shift all corners' anchor coordinates to become
 * 			closer to the expected position.
 * 		- The tweening functions active on the corners will handle updating the corners'
 * 			actual x/y position so that they are in the proper position relative to their
 * 			newly-moved anchor coordinates.
 * 
 * 	Cursor actions follows this pattern of logic:
 * 		- The cursor only reads inputs from the ActionInputHandler buffer when it is between
 * 			cursor movements.
 * 		- When the cursor reads inputs from the ActionInputHandler buffer, it reads all inputs
 * 			if possible, but will stop early if its input mode changes to DISABLED as a result
 * 			of processed action input.
 * 		Side note: This class was the whole reason why an input buffer setup was created for the
 * 			ActionInputHandler. Just processing inputs at the moment they arrived irrespective
 * 			of the cursor's position could cause menus to open and the cursor to disappear while
 * 			halfway between tiles, which looked especially bad when the camera was moving along
 * 			with the cursor.
 * 
 * @author Samuel Bumgardner
 */
class MapCursor implements UpdatingEntity implements HideableEntity implements Observed
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Variable to satisify UpdatingEntity interface.
	 * Determines whether this object should execute the body of its update function.
	 */
	public var active:Bool = false;
	
	/**
	 * Tracks whether the cursor is currently moving or not.
	 * Action inputs will be deferred until the cursor has finished moving.
	 */
	public var isMoving:Bool = false;
	
	/**
	 * Variable to satisfy Observed interface.
	 * Used to notify observers when input events occur.
	 */
	public var subject:Subject;
	
	/**
	 * Arrays for holding different sets of corner graphics, for use in different
	 * situations.
	 */
	private var normCornerArr:Array<AnchoredSprite> = new Array<AnchoredSprite>();
	private var targetCornerArr:Array<AnchoredSprite> = new Array<AnchoredSprite>();
	
	/**
	 * Shallow copy of the array that is currently being displayed by MapCursor.
	 * Should not be changed directly, but instead done by calling changeCurrCornerArr().
	 */
	private var currCornerArr:Array<AnchoredSprite>;
	
	/**
	 * Array of NumTween objects that act upon the corner that sits
	 * in the corresponding index of currCornerArr.
	 */
	private var cornerTweenArr:Array<NumTween> = new Array<NumTween>();
	
	/**
	 * Integers that track information about the cursor's current state, using 
	 * enums described below this class.
	 */
	private var currMoveMode:Int = MoveModes.NONE;
	private var currInputMode:Int = InputModes.FREE_MOVEMENT;
	/**
	 * FlxGroup containing all sprites under this object's supervision. Rather than
	 * directly adding MapCursor to the FlxState, this FlxGroup will be added.
	 */
	public var totalFlxGrp(default, null):FlxGroup = new FlxGroup();
	
	/**
	 * Sound effects that are played in response to various keyboard inputs.
	 */
	private var moveSound:FlxSound;
	private var confirmSound:FlxSound;
	
	/**
	 * Integers that track what row/column of the map's grid the MapCursor is in.
	 * Multiply by tileSize to find the x and y position of MapCursor.
	 */
	public var col(default, null):Int = 0;
	public var row(default, null):Int = 0;
	
	/**
	 * Set of integers that define the column and row boundaries of the map.
	 * 	maxCol and maxRow are set using parameters passed into new().
	 */
	private var minCol(default, never):Int = 0;
	private var minRow(default, never):Int = 0;
	private var maxCol:Int;
	private var maxRow:Int;
	
	/**
	 * Integer that holds the size of tiles used on the map, measured in pixels.
	 * Changing this value will alter the movement of this cursor significantly!
	 */
	private var tileSize:Int = 64;
	
	/**
	 * Number of frames the MapCursor takes to complete a single move between tiles.
	 */
	private var framesPerMove(default, never):Int = 6;
	
	/**
	 * Tracks the number of frames left in the current move.
	 */
	private var framesLeftInMove:Int = 0;
	
	/**
	 * Integers that track the x/y offset that corners will have, relative to the 
	 * "position" of the MapCursor. The L, R, T, & B stand for left, right, top, and bottom,
	 * respectively.
	 */
	private var currentAnchorLX:Int = 0;
	private var currentAnchorRX:Int = 0;
	private var currentAnchorTY:Int = 0;
	private var currentAnchorBY:Int = 0;
	
	/**
	 * Integers that hold the x/y offset that the cursor's top left corner's anchor 
	 * will have when that movement mode is active.
	 * 
	 * Note: Negative numbers result in outward offsets, positive numbers cause inward offsets.
	 */
	private var bounceInOutAnchorXY:Int = -5;
	
	private var expandedStillX:Int	= -8;
	private var expandedStillTY:Int	= -20;
	private var expandedStillBY:Int	= -8;
	
	/**
	 * FlxObject tracked by the camera inside the MissionState.
	 * This object was required because having the camera track a single corner caused
	 * 	problems due to the bouncing movement of corners, and the fact that they were
	 * 	often times outside of the square box the cursor logically takes up.
	 */
	public var cameraHitbox:FlxObject;
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	mapWidth	The width of the current map, in pixels.
	 * @param	mapHeight	The height of the current map, in pixels.
	 * @param	id			Passed along to the MapCursor's subject, used to identify itself when notifying events.
	 */
	public function new(mapWidth:Int, mapHeight:Int, ?id:Int = 0) 
	{	
		initSoundAssets();
		
		// The maxCol and maxRow shouldn't need to be floored, but better safe than sorry.
		maxCol = Math.floor(mapWidth / tileSize - 1);
		maxRow = Math.floor(mapHeight / tileSize - 1);
		
		subject = new Subject(this, id);
		cameraHitbox = new FlxObject(0, 0, tileSize, tileSize);
		
		initCornerGrp(AssetPaths.normal_cursor_corner__png, normCornerArr, true);
		initCornerGrp(AssetPaths.target_cursor_corner__png, targetCornerArr);
		bounceInOut(true);
	}
	
	/**
	 * Initializes all sound assets needed by this object.
	 */
	private function initSoundAssets():Void
	{
		moveSound = FlxG.sound.load(AssetPaths.cursor_move__wav);
		confirmSound = FlxG.sound.load(AssetPaths.cursor_confirm__wav);
	}
	
	/**
	 * Creates a set of 4 AnchoredSprites with identical graphics to be the corners of the cursor.
	 * Corners are created starting from the top-left corner and proceeding clockwise,
	 * and are added to both the provided array and the cursor's totalFlxGroup. Is also 
	 * responsible for setting a corner
	 * 
	 * @param	cornerGraphic	The provided graphic used by all corners 
	 * @param	cornerArr		Empty array that will contain references to a group of corners for later use.
	 * @param	beginActive		Indicates whether the provided group should be set as the first currCornerArr.
	 * @return	The array that was originally passed into the function, now full of sprites. Useful for chaining.
	 */
	private function initCornerGrp(cornerGraphic:FlxGraphicAsset, cornerArr:Array<AnchoredSprite>, ?beginActive:Bool = false):Array<AnchoredSprite>
	{
		var corner:AnchoredSprite;
		for (cornerType in 0...4)
		{
			corner = new AnchoredSprite(0, 0, cornerGraphic);
			
			if (cornerType == CornerTypes.TOP_RIGHT || cornerType == CornerTypes.BOTTOM_RIGHT)
			{
				corner.flipX = true;
			}
			if (cornerType == CornerTypes.BOTTOM_RIGHT || cornerType == CornerTypes.BOTTOM_LEFT)
			{
				corner.flipY = true;
			}
			
			if (!beginActive)
			{
				corner.visible = false; // All corner groups start inactive.
				corner.active = false;
			}
			
			cornerArr.push(corner);
			totalFlxGrp.add(corner);
		}
		
		if (beginActive)
		{
			currCornerArr = cornerArr.copy();
		}
		
		return cornerArr;
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Sets new values for row and col. The cursor will move toward the new position at
	 * normal speed.
	 * 
	 * @param	newRow	New value for row.
	 * @param	newCol	New value for col.
	 */
	public function moveToPosition(newRow:Int, newCol:Int):Void
	{
		row = newRow;
		col = newCol;
	}
	
	/**
	 * Sets new values for row and col, and immediately jumps the cursor's corners to the
	 * new position.
	 * 
	 * @param	newRow	New value for row.
	 * @param	newCol	New value for col.
	 */
	public function jumpToPosition(newRow:Int, newCol:Int):Void
	{
		row = newRow;
		col = newCol;
		jumpCursor();
	}
	
	/**
	 * Public function for changing movement modes. 
	 * 
	 * @param	newMovementMode	The desired movement mode. Use entries from MoveModes enum below.
	 */
	public function changeMovementModes(newMovementMode:Int):Void
	{
		switch (newMovementMode)
		{
			case MoveModes.BOUNCE_IN_OUT: bounceInOut();
			case MoveModes.EXPANDED_STILL: expandedStill();
			default: trace("ERROR: invalid MoveMode.");
		}
	}
	
	/**
	 * Public function for changing the cursor type.
	 * 
	 * @param	newCursorType	The desired cursor type. Use entries from CursorTypes enum below.
	 */
	public function changeCursorType(newCursorType:Int):Void
	{
		switch (newCursorType)
		{
			case CursorTypes.NORMAL:	changeCurrCornerArr(normCornerArr);
			case CursorTypes.TARGET:	changeCurrCornerArr(targetCornerArr);
			default: trace("ERROR: invalid CursorType.");
		}
	}
	
	/**
	 * Public function for changing input modes.
	 * 
	 * @param	newInputMode	The desired input mode. Use entries from InputModes enum below.
	 */
	public function changeInputModes(newInputMode:Int):Void
	{
		currInputMode = newInputMode;
	}
	
	/**
	 * Hides the MapCursor's corners from view.
	 */
	public function hide():Void
	{
		for (corner in currCornerArr)
		{
			corner.visible = false;
			corner.active = false;
		}
	}
	
	/**
	 * Reveals the MapCursor's corners.
	 */
	public function reveal():Void
	{
		for (corner in currCornerArr)
		{
			corner.visible = true;
			corner.active = true;
		}
	}
	
	/**
	 * Sets MapCursor to execute the body of its update() function when called.
	 */
	public function activate():Void
	{
		active = true;
	}
	
	/**
	 * Sets MapCursor to not execute the body of its update() function when called.
	 */
	public function deactivate():Void
	{
		active = false;
	}
	
	
	///////////////////////////////////////
	//        CORNER MANIPULATION        //
	///////////////////////////////////////
	
	/**
	 * Function for changing the curently displayed (and manipulated) corner array.
	 * Note that this does NOT make any changes to the array of tweens, so a new movement mode
	 * function must be called after this to make the corners move to their correct positions.
	 * 
	 * @param	newCornerArr	The array of corners that currCornerArr should become a shallow copy of.
	 */
	private function changeCurrCornerArr(newCornerArr:Array<AnchoredSprite>):Void
	{
		for (i in 0...currCornerArr.length)
		{
			currCornerArr[i].visible = false;
			currCornerArr[i].active = false;
			
			newCornerArr[i].setAnchor(currCornerArr[i].getAnchorX(), 
				currCornerArr[i].getAnchorY());
			newCornerArr[i].jumpToAnchor();
			
			newCornerArr[i].visible = true;
			newCornerArr[i].active = true;
		}
		
		currCornerArr = newCornerArr.copy();
	}
	
	/**
	 * Removes all tweens from cornerTweenArr, cancelling and destroying them along the way.
	 * Should be done whenever the cursor's movement mode needs to change.
	 */
	private function clearCurrentMoveMode():Void
	{
		var currTween:FlxTween;
		for (tween in 0...cornerTweenArr.length)
		{
			currTween = cornerTweenArr.pop();
			currTween.cancel();
			currTween.destroy();
		}
		currMoveMode = MoveModes.NONE;
	}
	
	
	///////////////////////////////////////
	//       CORNER MOVEMENT MODES       //
	///////////////////////////////////////
	
	/**
	 * Updates the movement cursor's current anchor variables, then changes each corner's 
	 * anchor variables to match those new values.
	 * Should be called when setting up anchor positions for the first time.
	 
	 * @param	newLX	The new x offset for anchors of left-side corners.
	 * @param	newRX	the new x offset for anchors of right-side corners.
	 * @param	newTY	the new y offset of anchors of top-side corners.
	 * @param	newBY	the new y offset of anchors of bottom-side corners.
	 */
	private function setAnchorPositions(newLX, newRX, newTY, newBY):Void
	{
		currentAnchorRX = newRX;
		currentAnchorLX = newLX;
		currentAnchorBY = newBY;
		currentAnchorTY = newTY;
		
		var xPos:Float = col * tileSize;
		var yPos:Float = row * tileSize;
		var newXAnchor:Float;
		var newYAnchor:Float;
		var cornerType = CornerTypes.TOP_LEFT;
		for (corner in currCornerArr)
		{
			// Set new anchor points
			if (cornerType == CornerTypes.TOP_RIGHT || cornerType == CornerTypes.BOTTOM_RIGHT)
			{	// If on the right side...
				newXAnchor = xPos + tileSize - (corner.width + currentAnchorRX); 
			}
			else
			{	// If on the left side...
				newXAnchor = xPos + currentAnchorLX;
			}
			if (cornerType == CornerTypes.BOTTOM_RIGHT || cornerType == CornerTypes.BOTTOM_LEFT)
			{	// If on the bottom...
				newYAnchor = yPos + tileSize  - (corner.width + currentAnchorRX);
			}
			else
			{	// If on the top...
				newYAnchor = yPos + currentAnchorTY;
			}
			corner.setAnchor(newXAnchor, newYAnchor);
			
			cornerType++;
		}
	}
	
	/**
	 * Similar to setAnchorPosition, but instead of setting up the anchors relative to
	 * the MapCursor's logical position, it just shifts the anchors from their current position
	 * to their new position.
	 * Should be called during movement mode change.
	 * 
	 * @param	newLX	The new x offset for anchors of left-side corners.
	 * @param	newRX	the new x offset for anchors of right-side corners.
	 * @param	newTY	the new y offset of anchors of top-side corners.
	 * @param	newBY	the new y offset of anchors of bottom-side corners.
	 */
	private function changeAnchorPositions(newLX, newRX, newTY, newBY):Void
	{
		var diffRX = newRX - currentAnchorRX;
		var diffLX = newLX - currentAnchorLX;
		var diffBY = newBY - currentAnchorBY;
		var diffTY = newTY - currentAnchorTY;
		currentAnchorRX = newRX;
		currentAnchorLX = newLX;
		currentAnchorBY = newBY;
		currentAnchorTY = newTY;
		
		var newXAnchor:Float;
		var newYAnchor:Float;
		var cornerType = CornerTypes.TOP_LEFT;
		for (corner in currCornerArr)
		{
			// Set new anchor points
			if (cornerType == CornerTypes.TOP_RIGHT || cornerType == CornerTypes.BOTTOM_RIGHT)
			{	// If on the right side...
				newXAnchor = corner.getAnchorX() - diffRX; 
			}
			else
			{	// If on the left side...
				newXAnchor = corner.getAnchorX() + diffLX;
			}
			if (cornerType == CornerTypes.BOTTOM_RIGHT || cornerType == CornerTypes.BOTTOM_LEFT)
			{	// If on the bottom...
				newYAnchor = corner.getAnchorY() - diffBY;
			}
			else
			{	// If on the top...
				newYAnchor = corner.getAnchorY() + diffTY;
			}
			corner.setAnchor(newXAnchor, newYAnchor);
			
			cornerType++;
		}
	}
	
	/**
	 * Tween function for use in a NumTween created in bounceInOut().
	 * 
	 * Because HaxeFlixel doesn't allow looping chained tweens, I had to do a bit of a hacky
	 * function here to make the whole movement in a single tween. Basically, when the bounce
	 * is half over (offsetValue > corner.width /2) offsetValue is changed so it counts back to
	 * zero, making the first half move the square inward, and the second half expand it again.
	 * 
	 * @param	corner			The corner object being tweened.
	 * @param	cornerType		Which corner this particular object is. (See CornerTypes enum)
	 * @param	offsetValue		How far the corner should be offset from its anchor.
	 */
	private function bounceFunc(corner:AnchoredSprite, cornerType:Int, offsetValue:Float):Void
	{
		if (offsetValue > corner.width / 2)
		{
			offsetValue = corner.width - offsetValue;
		}
		
		var offsetX:Float = offsetValue;
		var offsetY:Float = offsetValue;
		
		if (cornerType == CornerTypes.TOP_RIGHT || cornerType == CornerTypes.BOTTOM_RIGHT)
		{
			offsetX *= -1; 
		}
		if (cornerType == CornerTypes.BOTTOM_RIGHT || cornerType == CornerTypes.BOTTOM_LEFT)
		{
			offsetY *= -1;
		}
		
		corner.x = corner.getAnchorX() + offsetX;
		corner.y = corner.getAnchorY() + offsetY;
	}
	
	/**
	 * Changes the cursor's movement mode to BOUNCE_IN_OUT, which involves the following:
	 * 	removing the current set of tweens affecting the corners.
	 * 	changing the anchor positions of the four corners
	 * 	setting up new tweens for each of the corners.
	 * 
	 * @param	setPositions	Determines whether anchor positions need to be set or changed.
	 */
	private function bounceInOut(?setPositions:Bool = false):Void
	{
		// Remove old tweens
		clearCurrentMoveMode();
		
		if (setPositions)
		{
			setAnchorPositions(bounceInOutAnchorXY, bounceInOutAnchorXY, bounceInOutAnchorXY,
				bounceInOutAnchorXY);
		}
		else
		{
			changeAnchorPositions(bounceInOutAnchorXY, bounceInOutAnchorXY, bounceInOutAnchorXY,
				bounceInOutAnchorXY);
		}
		var newTween:NumTween;
		var cornerType = CornerTypes.TOP_LEFT;
		for (corner in currCornerArr)
		{	
			// Set up new tweens
			newTween = FlxTween.num(0, corner.width, 1, {ease: FlxEase.circInOut, 
				startDelay: .20, loopDelay: .20, type: FlxTween.LOOPING}, 
				bounceFunc.bind(corner, cornerType));
			
			cornerTweenArr.push(newTween);
			
			cornerType++;
		}
		
		currMoveMode = MoveModes.BOUNCE_IN_OUT;
	}
	
	/**
	 * Tween function for use in a NumTween created in expandedStill().
	 * Doesn't do much, just ensures that the corners are following their anchors.
	 * 
	 * @param	elapsed		Time since last call to stillFunc, in seconds
	 */
	private function stillFunc(corner:AnchoredSprite, elapsed:Float):Void
	{
		corner.x = corner.getAnchorX();
		corner.y = corner.getAnchorY();
	}
	
	/**
	 * Changes cursor's movement mode to EXPANDED_STILL, which means new anchors and tweens.
	 * 
	 * @param	setPositions	Determines whether anchor positions need to be set or changed.
	 */
	private function expandedStill(?setPositions:Bool = false):Void
	{
		// Remove old tweens
		clearCurrentMoveMode();
		
		if (setPositions)
		{
			setAnchorPositions(expandedStillX, expandedStillX, expandedStillTY, expandedStillBY);
		}
		else
		{
			changeAnchorPositions(expandedStillX, expandedStillX, expandedStillTY, 
				expandedStillBY);
		}
		
		var newTween:NumTween;
		for (corner in currCornerArr)
		{	
			// Set up new tweens
			newTween = FlxTween.num(0, 1, 1, {type: FlxTween.LOOPING}, stillFunc.bind(corner));
			
			cornerTweenArr.push(newTween);
		}
		
		currMoveMode = MoveModes.EXPANDED_STILL;
	}
	
	
	///////////////////////////////////////
	//          CURSOR MOVEMENT          //
	///////////////////////////////////////
	
	/**
	 * After checking that the attempted movement is valid, changes col and row variables 
	 * 	of the cursor & plays movement sound effect.
	 * 
	 * @param	colRowChanges	A point with contents (column change amount, row change amount)
	 */
	private function moveCursorPos(vertMove:Int, horizMove:Int, heldMove:Bool):Void
	{	
		// If vertical movement is not valid, set to 0.
		if (!(row + vertMove >= minRow && row + vertMove <= maxRow))
		{
			vertMove = 0;
		}
		
		// If horizontal movement is not valid, set to 0.
		if (!(col + horizMove >= minCol && col + horizMove <= maxCol))
		{
			horizMove = 0;
		}
		
		var xPos:Int = col * tileSize;
		var yPos:Int = row * tileSize;
		
		if (// If at least one of the movement directions was valid...
			(vertMove != 0 || horizMove != 0) &&
			// If the movement is "held", then only move if not currently moving.
			(!heldMove || !isMoving)
			)
		{
			row += vertMove;
			col += horizMove;
			framesLeftInMove = framesPerMove;
			isMoving = true;
			moveSound.play(true);
			subject.notify(EventTypes.MOVE);
		}
	}
	
	/**
	 * Moves the cursor's corners toward the cursor's position incrementally.
	 */
	private function moveCornerAnchors():Void
	{
		if (framesLeftInMove > 0)
		{
			var xPos:Float = col * tileSize;
			var yPos:Float = row * tileSize;
			
			var remainingX:Float = xPos + currentAnchorLX - currCornerArr[0].getAnchorX();
			var remainingY:Float = yPos + currentAnchorTY - currCornerArr[0].getAnchorY();
			
			for (corner in currCornerArr)
			{
				corner.setAnchor(corner.getAnchorX() + remainingX / framesLeftInMove, 
					corner.getAnchorY() + remainingY / framesLeftInMove);
			}
			
			framesLeftInMove--;
			
			if (currCornerArr[0].getAnchorX() == xPos + currentAnchorLX &&
				currCornerArr[0].getAnchorY() == yPos + currentAnchorTY)
			{
				isMoving = false;
			}
		}
	}
	
	/**
	 * Changes the cameraHitbox x and y values to match the position of the top left
	 * 	corner's anchor location minus the anchor's offset. 
	 * This allows the cameraHitbox to move smoothly around.
	 */
	private function updateCameraHitboxPos():Void
	{
		cameraHitbox.x = currCornerArr[CornerTypes.TOP_LEFT].getAnchorX() - currentAnchorLX;
		cameraHitbox.y = currCornerArr[CornerTypes.TOP_LEFT].getAnchorY() - currentAnchorTY;
	}
	
	/**
	 * Jumps the corners' anchors and x/y values to match the cursor's current position.
	 * Also updates the cameraHitbox position to match.
	 */
	private function jumpCursor():Void
	{
		var xDifference = col * tileSize + currentAnchorLX - currCornerArr[0].getAnchorX();
		var yDifference = row * tileSize + currentAnchorTY - currCornerArr[0].getAnchorY();
		
		// Change corner anchors and move corner sprites.
		for (corner in currCornerArr)
		{
			corner.setAnchor(corner.getAnchorX() + xDifference, 
				corner.getAnchorY() + yDifference);
			corner.jumpToAnchor();
		}
		
		// Change cameraHitbox position.
		cameraHitbox.x += xDifference;
		cameraHitbox.y += yDifference;
	}
	
	
	///////////////////////////////////////
	//          CURSOR ACTIONS           //
	///////////////////////////////////////
	
	/**
	 * Can (and probably should) be overridden by child classes of this, since different
	 * 	menus may not need to notify PAINT, NEXT, or INFO events. If it is overridden with
	 * 	the intent to replace this function, make sure to NOT call super.doCursorAction();
	 * 
	 * @param	pressedKeys	Indicates which inputs were pressed this frame. See ActionInputHandler's KeyIndex enum to map indexes to key types.
	 * @param	heldAction	Indicates if the action was caused by held inputs or not.
	 */
	private function doCursorAction(pressedKeys:Array<Bool>, heldAction:Bool):Void
	{
		if (!heldAction)
		{
			// Could also be done with a loop, but this ends up being easier to understand.
			if (pressedKeys[KeyIndex.CONFIRM])
			{
				confirmSound.play(true);
				subject.notify(EventTypes.CONFIRM);
			}
			else if (pressedKeys[KeyIndex.CANCEL])
			{
				subject.notify(EventTypes.CANCEL);
			}
			else if (pressedKeys[KeyIndex.PAINT])
			{
				subject.notify(EventTypes.PAINT);
			}
			else if (pressedKeys[KeyIndex.NEXT])
			{
				subject.notify(EventTypes.NEXT);
			}
			else if (pressedKeys[KeyIndex.INFO])
			{
				subject.notify(EventTypes.INFO);
			}
		}
	}
	
	
	///////////////////////////////////////
	//         UPDATE FUNCTIONS          //
	///////////////////////////////////////
	
	/**
	 * Since this object isn't going to be "added" to the game state
	 * (and thus doesn't recieve any updates naturally) it's up to the 
	 * state to call this object's update manually.
	 * 
	 * NOTE:
	 * 	See the top of the file for an explanation of why an input buffering system
	 * 		exists and the general idea of how it operates.
	 * 
	 * NOTE: 
	 * 	Because MapCursor's update() function is currently called after super.update()
	 * 		inside of the MissionState, updateCameraHitboxPos() must be called before
	 * 		moveCornerAnchors().
	 * 	This is necessary because the corners' tweening functions update at some point
	 * 		during the MissionState's super.update(), which sets the corners' visual 
	 * 		positions to whatever the anchor positions are at that moment (after adding
	 * 		and/or subtracting any necessary offsets).
	 * 	We need to make sure that the anchor values used for changing the corners' visual
	 * 		positions and the anchor values used for changing the cameraHitbox's position
	 * 		are the same, otherwise the two will get offset from one another by one frame.
	 * 
	 * 	Basically, we need the corners' tweens' updates and updateCameraHitbox() to occur
	 * 		on the same side of moveCornerAnchors(), otherwise one will get ahead of the other
	 * 		by one frame during movement.
	 * 	Because MapCursor is updated after MissionState's super.update() (which updates the
	 * 		tweens) we need to make sure that the camera hitbox is updated before corner
	 * 		anchors move.
	 * 	If MapCursor's update() call in MissionState is ever moved to be before super.update(),
	 * 		then we will need to move updateCameraHitbox() to happen after MoveCornerAnchors().
	 * 	That way, updateCameraHitbox() and the tween updates will happen with the same anchor
	 * 		values, ensuring that the camera hitbox and corner positions remain in sync with
	 * 		one another.
	 * 
	 * @param	elapsed
	 */
	public function update(elapsed:Float):Void
	{
		if (active)
		{
			// Actions should remain buffered until movement ends.
			if (!isMoving)
			{
				// Call all of the buffered action functions in order.
				while (currInputMode != InputModes.DISABLED && 
					ActionInputHandler.actionBuffer.length > ActionInputHandler.numInputsUsed)
				{
					ActionInputHandler.useBufferedInput(doCursorAction);
				}
			}
			
			
			if (currInputMode != InputModes.DISABLED)
			{
				MoveInputHandler.handleMovement(elapsed, moveCursorPos);
			}
			
			updateCameraHitboxPos();
			moveCornerAnchors();
		}
	}
}

@:enum
class CornerTypes
{
	public static var TOP_LEFT 		(default,never)	= 0;
	public static var TOP_RIGHT 	(default,never)	= 1;
	public static var BOTTOM_RIGHT 	(default,never)	= 2;
	public static var BOTTOM_LEFT 	(default,never)	= 3;
}

@:enum
class MoveModes
{
	public static var NONE 			(default,never)	= -1;
	public static var BOUNCE_IN_OUT	(default,never)	= 0;
	public static var EXPANDED_STILL(default,never)	= 1;
}

@:enum
class CursorTypes
{
	public static var NORMAL	(default, never) = 0;
	public static var TARGET	(default, never) = 1;
}

@:enum
class InputModes
{
	public static var DISABLED		(default, never) = 0;
	public static var FREE_MOVEMENT	(default, never) = 1;
	public static var UNIT_SELECTED	(default, never) = 2;
}