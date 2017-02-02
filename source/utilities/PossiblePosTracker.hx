package utilities;
import flixel.math.FlxPoint;

/**
 * Simple class that bundles together information about where an object may need to be
 * 	positioned.
 * 
 * Includes variables for "left" and "right" X values and "top" and "bottom" Y values.
 * 
 * Is needed to handle things like the action menu, which should appear on the opposite
 * 	side of the screen from the player's cursor, or the additional info windows in a mission, 
 * 	which need to move between different possible positions in the four corners of the screen
 *  in response to cursor movement.
 * 
 * Should be used by objects with manager-type responsibilities over the object that needs
 * 	to be repositioned, I think.
 * 
 * The menu doesn't need to know where it may need to be positioned relative to other things,
 * 	its manager will keep track of that and tell it to move between different positions at
 * 	the appropriate time.
 * 
 * @author Samuel Bumgardner
 */
class PossiblePosTracker
{

	/**
	 * X value that should be used when the object is displayed on the left.
	 */
	public var leftX(default, null):Float;
	
	/**
	 * X value that should be used when the object is displayed on the right.
	 */
	public var rightX(default, null):Float;
	
	/**
	 * Y value that should be used when the object is displayed at the top.
	 */
	public var topY(default, null):Float;
	
	/**
	 * Y value that should be used when the object is displayed at the bottom.
	 */
	public var bottomY(default, null):Float;
	
	/**
	 * Initializer
	 * 
	 * @param	leftPosX	X value to be used when the object is to the left.
	 * @param	rightPosX	X value to be used when the object is to the right.
	 * @param	rightPosX	Y value to be used when the object is at the top.
	 * @param	rightPosY	Y value to be used when the object is at the bottom.
	 */
	public function new(leftPosX:Float, rightPosX:Float, topPosY:Float, bottomPosY:Float) 
	{
		leftX = leftPosX;
		rightX = rightPosX;
		topY = topPosY;
		bottomY = bottomPosY;
	}
}