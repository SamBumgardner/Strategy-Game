package cursors;

import cursors.AnchoredSprite;
import flixel.FlxG;
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
	private var col:Int = 0;
	private var row:Int = 0;
	
	/**
	 * Integer that holds the size of tiles used on the map, measured in pixels.
	 * Changing this value will alter the movement of this cursor significantly!
	 */
	private var tileSize:Int = 64;
	
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
	 * Tracks if any new inputs have been entered in this frame.
	 * Used in processMovementInput() and attemptHeldMovement()
	 */
	private var moveInputChanged:Bool = false;
	
	/**
	 * Tracks the total amount of time that the current set of directional inputs
	 * have been held for. Used in attemptHeldMovement().
	 */
	private var timeMoveHeld:Float = 0;
	
	/**
	 * The minimum amount of time the button must be held to start continuously moving.
	 */
	private var timeMoveHeldThreshold(default, null):Float = .25;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 */
	public function new(?id:Int = 0) 
	{	
		initSoundAssets();
		
		subject = new Subject(this, id);
		
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
		jumpCorners();
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
	 * Changes col and row variables of the cursor & plays movement sound effect.
	 * 
	 * @param	colRowChanges	A point with contents (column change amount, row change amount)
	 */
	private function moveCursorPos(vertMove:Int, horizMove:Int, heldMove:Bool):Void
	{	
		var xPos:Int = col * tileSize;
		var yPos:Int = row * tileSize;
		if (!heldMove || //If the movement is "held", then only move if not currently moving.
			(currCornerArr[0].getAnchorX() == xPos + currentAnchorLX &&
			currCornerArr[0].getAnchorY() == yPos + currentAnchorTY))
		{
			row += vertMove;
			col += horizMove;
			moveSound.play(true);
		}
	}
	
	/**
	 * Moves the cursor's corners toward the cursor's position incrementally.
	 */
	private function moveCornerAnchors():Void
	{
		var xPos:Float = col * tileSize;
		var yPos:Float = row * tileSize;
		
		var horizMove:Int	= 0;
		var vertMove:Int	= 0;
		
		var framesPerMove:Int = 4;
		
		if (currCornerArr[0].getAnchorX() > xPos + currentAnchorLX)
		{
			horizMove--;
		}
		else if (currCornerArr[0].getAnchorX() < xPos + currentAnchorLX)
		{
			horizMove++;
		}
		if (currCornerArr[0].getAnchorY() > yPos + currentAnchorTY)
		{
			vertMove--;
		}
		else if (currCornerArr[0].getAnchorY() < yPos + currentAnchorTY)
		{
			vertMove++;
		}
		
		for (corner in currCornerArr)
		{
			corner.setAnchor(corner.getAnchorX() + (tileSize / framesPerMove * horizMove),
				corner.getAnchorY() + (tileSize / framesPerMove * vertMove));
		}
	}
	
	/**
	 * Jumps the corners' anchors and x/y values to match the cursor's current position.
	 */
	private function jumpCorners():Void
	{
		var xDifference = col * tileSize + currentAnchorLX - currCornerArr[0].getAnchorX();
		var yDifference = row * tileSize + currentAnchorTY - currCornerArr[0].getAnchorY();
		
		for (corner in currCornerArr)
		{
			corner.setAnchor(corner.getAnchorX() + xDifference, 
				corner.getAnchorY() + yDifference);
			corner.jumpToAnchor();
		}
	}
	
	
	///////////////////////////////////////
	//          CURSOR ACTIONS           //
	///////////////////////////////////////
	
	/**
	 * Is not expecting to ever get a call with heldAction being true (because of its call
	 * 	to ActionInputHandler, see below in the update function) but I set up the test at
	 * 	the start of the function just in case.
	 * 
	 * Can (and probably should) be overridden by child classes of this, since different
	 * 	menus may not need to notify PAINT, NEXT, or INFO events. If it is overridden with
	 * 	the intent to replace this function, make sure to NOT call super.doCursorAction();
	 * 
	 * @param	pressedKeys
	 * @param	heldAction
	 */
	private function doCursorAction(pressedKeys:Array<Bool>, heldAction:Bool)
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
	 * Handles resetting any variables necessary at the end of an update cycle.
	 */
	public function cleanupVariables():Void
	{
		moveInputChanged = false;
	}
	
	/**
	 * Since this object isn't going to be "added" to the game state
	 * (and thus doesn't recieve any updates naturally) it's up to the 
	 * state to call this object's update manually.
	 * 
	 * @param	elapsed
	 */
	public function update(elapsed:Float):Void
	{
		if (active)
		{
			// NOTE: This section is temporary, and will likely be replaced by game logic later.
			
			if (currMoveMode != MoveModes.EXPANDED_STILL && FlxG.keys.pressed.ALT)
			{
				expandedStill();
			}
			else if (currMoveMode != MoveModes.BOUNCE_IN_OUT && !FlxG.keys.pressed.ALT)
			{
				bounceInOut();
			}
			
			// Compare [0] index of arrays as a shortcut to see if they contain the same elements.
			if (currCornerArr[0] != targetCornerArr[0] && FlxG.keys.pressed.CONTROL)
			{
				changeCurrCornerArr(targetCornerArr);
				if (currMoveMode == MoveModes.EXPANDED_STILL)
				{
					expandedStill();
				}
				else
				{
					bounceInOut();
				}
			}
			else if (currCornerArr[0] != normCornerArr[0] && !FlxG.keys.pressed.CONTROL)
			{
				changeCurrCornerArr(normCornerArr);
				if (currMoveMode == MoveModes.EXPANDED_STILL)
				{
					expandedStill();
				}
				else
				{
					bounceInOut();
				}
			}
			
			// NOTE: end of likely-to-be-replaced section.
			
			if (currInputMode != InputModes.DISABLED)
			{
				ActionInputHandler.handleActions(elapsed, doCursorAction, false);
				MoveInputHandler.handleMovement(elapsed, moveCursorPos);
			}
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