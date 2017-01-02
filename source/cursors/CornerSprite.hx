package cursors;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * A single corner of a MapCursor. This class is designed to do small movements
 * around its "anchor coordinates" and not much else. That movement logic is specified
 * inside MapCursor, so head over there to see how this class is used.
 * 
 * @author Samuel Bumgardner
 */
class CornerSprite extends FlxSprite
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Floating point numbers for remembering the position that this sprite
	 * should tween to and from when doing different movements.
	 */
	private var anchorX:Float;
	private var anchorY:Float;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	X				The starting x coordinate for this sprite.
	 * @param	Y				The starting y coordinate for this sprite.
	 * @param	SimpleGraphic	The single-frame graphic of the corner.
	 * @param	shouldFlipX		Whether this corner's graphic should be flipped horizontally.
	 * @param	shouldFlipY		Whether this corner's graphic should be flipped vertically.
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?SimpleGraphic:FlxGraphicAsset, 
		?shouldFlipX:Bool = false, ?shouldFlipY:Bool = false) 
	{
		super(X, Y, SimpleGraphic);
		if (shouldFlipX)
		{
			flipX = true;
		}
		if (shouldFlipY)
		{
			flipY = true;
		}
		anchorX = X;
		anchorY = Y;
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Public getter method for anchorX.
	 * 
	 * @return anchorX's value.
	 */
	public function getAnchorX():Float
	{
		return anchorX;
	}
	
	/**
	 * Public getter method for anchorY.
	 * 
	 * @return anchorY's value.
	 */
	public function getAnchorY():Float
	{
		return anchorY;
	}
	
	/**
	 * Sets new anchor coordinates for this corner.
	 * Useful when jumping from one position to another.
	 * 
	 * @param	newX	New value for anchorX.
	 * @param	newY	New value for anchorY.
	 */
	public function setAnchor(newX:Float, newY:Float):Void
	{
		anchorX = newX;
		anchorY = newY;
	}
	
	/**
	 * Shifts this corner's anchor points by deltaX and deltaY.
	 * Useful when moving relative to its current position.
	 * 
	 * @param	deltaX	Amount to change anchorX by.
	 * @param	deltaY	Amount to change anchorY by.
	 */
	public function moveAnchor(deltaX:Float, deltaY:Float):Void
	{
		anchorX += deltaX;
		anchorY += deltaY;
	}
	
	public function jumpToAnchor():Void
	{
		x = anchorX;
		y = anchorY;
	}
}