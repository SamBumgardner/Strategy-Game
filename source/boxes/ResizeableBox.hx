package boxes;

import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import utilities.HideableEntity;

/**
 * Resizeable boxes, used in a situation where a box's size should change depending different
 * 	context-sensitive variables. Generating a bunch of boxes for every concievable situation
 * 	could work, but that would be a pretty wasteful solution by comparison.
 * 
 * To make and use a resizeable box, you specify the maximum dimensions of the box and a few
 * 	other values to indicate what graphics the box should use. After the box is instantiated,
 * 	it can be resized, moved, and hidden at will via public-facing functions.
 * 
 * NOTE: it's possible to change the box's components' x & y values without calling
 * 	setPos() if the components are accessed via totalFlxGrp. If you decide to do that,
 * 	make sure to manually update the box's x & y variables too, otherwise the box won't
 * 	move correctly if setPos() is called in the future.
 * 
 * @author Samuel Bumgardner
 */
class ResizeableBox implements HideableEntity implements VarSizedBox
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Maximum width of the box. Set by parameter to new().
	 */
	public var maxWidth(default, null):Int;
	
	/**
	 * Maximum height of the box. Set by parameter to new().
	 */
	public var maxHeight(default, null):Int;
	
	/**
	 * Current width of the box. Initally set to match maxWidth.
	 * Changed in resize().
	 */
	public var boxWidth(default, null):Int;
	
	/**
	 * Current height of the box. Initally set to match maxHeight.
	 * Changed in resize().
	 */
	public var boxHeight(default, null):Int;
	
	/**
	 * Graphic asset used as the box's spritesheet. Set by parameter to new().
	 * Passed into BoxCreator setup function.
	 */
	public var boxSpriteSheet(default, null):FlxGraphicAsset;
	
	/**
	 * Size of the corner/border components of the spritesheet. Set by parameter to new().
	 * Passed into BoxCreator setup function. 
	 * Also used for some positioning calculations.
	 */
	public var cornerSize(default, null):Int;
	
	/**
	 * Size of the corner/border components of the spritesheet. Set by parameter to new().
	 * Passed into BoxCreator setup function. 
	 */
	public var backgroundSize(default, null):Int;
	
	/**
	 * Rectangle used as boxSprite's clipRect to make the graphic match resized dimensions.
	 */
	private var boxClipRect:FlxRect;
	
	/**
	 * Sprite created by BoxCreator. The default graphic for a box of maximum size.
	 * Can be used as a smaller box as well by clipping its graphic to the smaller
	 * 	size and setting right edge, bottom edge, and corner graphic graphics over the
	 * 	cut off ends of the box.
	 */
	private var boxSprite:FlxSprite;
	
	/**
	 * Rectangle used as bottomEdge's clipRect to make the graphic match resized dimensions.
	 */
	private var bottomClipRect:FlxRect;
	
	/**
	 * Sprite created by BoxCreator. 
	 * Is displayed over the bottom edge of boxSprite to cover the clipped-off edge of the box 
	 * 	when the box is at a non-maximum height.
	 * This sprite must also be clipped when the box changes width, because it shouldn't hang
	 * 	past the new dimensions of the box.
	 */
	private var bottomEdge:FlxSprite;
	
	/**
	 * Rectangle used as rightEdge's clipRect to make the graphic match resized dimensions.
	 */
	private var rightClipRect:FlxRect;
	
	/**
	 * Sprite created by BoxCreator. 
	 * Is displayed over the right edge of boxSprite to cover the clipped-off edge of the box 
	 * 	when the box is at a non-maximum width.
	 * This sprite must also be clipped when the box changes height, because it shouldn't hang
	 * 	past the new dimensions of the box.
	 */
	private var rightEdge:FlxSprite;
	
	/**
	 * Sprite created by BoxCreator.
	 * Is displayed over all other sprites, and sits in the bottom left corner of the resized 
	 * 	box to cover up the clipped-off edges of the boxSprite and two edge sprites that occur
	 * 	when the box is sized at a non-maximum width or height.
	 */
	private var bottomRightCorner:FlxSprite;
	
	
	/**
	 * FlxGroup containing all FlxBasic-inheriting objects owned by this Resizeable box.
	 */
	public var totalFlxGrp(default, null):FlxGroup = new FlxGroup();
	
	/**
	 * x coordinate that all box components should be positioned relative to.
	 */
	private var x:Float = 0;
	
	/**
	 * y coordinate that all box components should be positioned relative to.
	 */
	private var y:Float = 0;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	X			x-coordinate for the resizeable box.
	 * @param	Y			y-coordinate for the resizeable box.
	 * @param	maximumWidth	Maximum & initial width of the box.
	 * @param	maximumHeight	Maximum & initial height of the box.
	 * @param	spriteSheet		Spritesheet used to generate box graphic. See BoxCreator for specifications.
	 * @param	cSize			Size of the corner/border sections of the box graphic.
	 * @param	bgSize			Size of the background sections of the box graphic.
	 */
	public function new(X:Float, Y:Float, maximumWidth:Int, maximumHeight:Int, 
		spriteSheet:FlxGraphicAsset, cSize:Int, bgSize:Int) 
	{
		maxWidth = maximumWidth;
		maxHeight = maximumHeight;
		
		boxWidth = maxWidth;
		boxHeight = maxHeight;
		
		boxSpriteSheet = spriteSheet;
		cornerSize = cSize;
		backgroundSize = bgSize;
		
		initBoxComponents();
		
		setPos(X, Y);
	}
	
	/**
	 * Sets up boxSprite, bottomEdge, rightEdge, and bottomRightCorner.
	 * Requires variable setup to be already completed.
	 */
	private function initBoxComponents():Void
	{
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		boxSprite = BoxCreator.createBox(maxWidth, maxHeight);
		boxClipRect = new FlxRect(0, 0, boxWidth, boxHeight);
		boxSprite.clipRect = boxClipRect;
		
		bottomEdge = BoxCreator.createBottomEdge(boxWidth);
		bottomEdge.y = y + boxHeight - cornerSize;
		bottomClipRect = new FlxRect(0, 0, boxWidth, cornerSize);
		bottomEdge.clipRect = bottomClipRect;
		
		rightEdge = BoxCreator.createRightEdge(boxHeight);
		rightEdge.x = x + boxWidth - cornerSize;
		rightClipRect = new FlxRect(0, 0, cornerSize, boxHeight);
		rightEdge.clipRect = rightClipRect;
		
		bottomRightCorner = BoxCreator.createCorner(true, true);
		bottomRightCorner.x = x + boxWidth - cornerSize;
		bottomRightCorner.y = y + boxHeight - cornerSize;
		
		totalFlxGrp.add(boxSprite);
		totalFlxGrp.add(bottomEdge);
		totalFlxGrp.add(rightEdge);
		totalFlxGrp.add(bottomRightCorner);
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Resizes box to match whatever size was provided in the parameters.
	 * Will cause a broken/incorrect graphic if resized to values larger
	 * 	than maxWidth or maxHeight.
	 * 
	 * NOTE:
	 * 	cornerSize is subtracted from boxWidth and boxHeight when setting
	 * 		clipping rectangle sizes so there is absolutely no overlap 
	 * 		between any visible components. If overlap does occur, then
	 * 		borders/corners with transparent components will reveal the
	 * 		borders/body images that they are overlapping, which is bad.
	 * 
	 * @param	newWidth	The new width the box should have.
	 * @param	newHeight	The new height the box should have.
	 */
	public function resize(newWidth:Int, newHeight:Int):Void
	{
		if (newWidth > maxWidth || newHeight > maxHeight)
		{
			trace("ERROR: resizeable boxes are not allowed to change size to any dimensions " +
				"greater than their original size.");
		}
		
		boxWidth = newWidth;
		boxHeight = newHeight;
		
		boxClipRect.setSize(boxWidth - cornerSize, boxHeight - cornerSize);
		boxSprite.clipRect = boxClipRect;
		
		bottomEdge.y = y + boxHeight - cornerSize;
		bottomClipRect.setSize(boxWidth - cornerSize, cornerSize);
		bottomEdge.clipRect = bottomClipRect;
		
		rightEdge.x = x + boxWidth - cornerSize;
		rightClipRect.setSize(cornerSize, boxHeight - cornerSize);
		rightEdge.clipRect = rightClipRect;
		
		bottomRightCorner.x = x + boxWidth - cornerSize;
		bottomRightCorner.y = y + boxHeight - cornerSize;
	}
	
	/**
	 * Public function for changing the position of the box and all of its components.
	 * 
	 * @param	newX	The box's new x value.
	 * @param	newY	The box's new y value.
	 */
	public function setPos(newX:Float, newY:Float):Void
	{
		var xDiff:Float = newX - x;
		var yDiff:Float = newY - y;
		
		x = newX;
		y = newY;
		
		totalFlxGrp.forEach(moveObject.bind(_, xDiff, yDiff), true);
	}
	
	/**
	 * Helper function used by setPos().
	 * Is passed as the argument into an FlxGroup's forEach() to change the x values of all
	 * 	sprites in the box's totalFlxGrp. 
	 * Because totalFlxGroup holds objects of type FlxBasic, the function has to test that the 
	 * 	"targetSprite" FlxBasic object is actually an FlxObject (or something that inherits 
	 * 	from it) so it has an x & y component to change.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 * @param	dX				The amount the targetObject's x should change by.
	 * @param	dY				The amount the targetObject's y should change by.
	 */
	private function moveObject(targetObject:FlxBasic, dX:Float, dY:Float):Void
	{
		if (Std.is(targetObject, FlxObject))
		{
			(cast targetObject).x += dX;
			(cast targetObject).y += dY;
		}
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the box's totalFlxGrp invisible and inactive.
	 * Copied from MenuTemplate.
	 */
	public function hide():Void
	{
		totalFlxGrp.forEach(hideSprite, true);
	}
	
	/**
	 * Helper function used by hide().
	 * Takes an FlxBasic as a parameter, determines if it is an FlxSprite, and if it is
	 * 	it makes it invisible and inactive.
	 * It is necessary to check if the targetSprite is an FlxSprite because the FlxGroup
	 * 	it is used on is only guaranteed to have FlxBasic objects, which may or may not be
	 * 	sprites that need to be hidden.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 */
	private function hideSprite(targetSprite:FlxBasic):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).visible = false;
			(cast targetSprite).active = false;
		}
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the box's totalFlxGrp invisible and inactive.
	 * Copied from MenuTemplate.
	 */
	public function reveal():Void
	{
		totalFlxGrp.forEach(revealSprite, true);
	}
	
	/**
	 * Helper function for reveal().
	 * Takes an FlxBasic as a parameter, determines if it is an FlxSprite, and if it is
	 * 	it makes it visible and active.
	 * It is necessary to check if the targetSprite is an FlxSprite because the FlxGroup
	 * 	it is used on is only guaranteed to have FlxBasic objects, which may or may not be
	 * 	sprites that need to be hidden.
	 * 
	 * @param	targetSprite	
	 */
	private function revealSprite(targetSprite:FlxBasic):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).visible = true;
			(cast targetSprite).active = true;
		}
	}
	
}