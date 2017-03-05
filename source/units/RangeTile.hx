package units;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * Extension of FlxSprite used to show the movement and attack ranges of units.
 * 
 * @author Samuel Bumgardner
 */
class RangeTile extends FlxSprite
{
	/**
	 * Tracks whether this RangeTile is displaying movement range (true) or
	 * 	attack range (false). By changing this, the tile's animation is 
	 * 	automatically changed to match.
	 */
	public var moveMode(default, set):Bool = true;
	
	/**
	 * Initializer.
	 * 
	 * @param	X	The tile's starting X value.
	 * @param	Y	The tile's starting Y value.
	 */
	public function new(?X:Float=0, ?Y:Float=0) 
	{
		super(X, Y);
		
		loadGraphic(AssetPaths.range_tiles__png, true, 64, 64);
		animation.add("move", [0], 1, true);
		animation.add("attack", [1], 1, true);
		
		alpha = .4;
		
		moveMode = true;
		
		active = false;
	}
	
	/**
	 * Setter method for the moveMode variable. 
	 * Switches the tile's animation to reflect the new value of moveMode in addition
	 * 	to changing the variable.
	 * @param	newMoveMode
	 * @return
	 */
	public function set_moveMode(newMoveMode:Bool):Bool
	{
		if (newMoveMode)
		{
			animation.play("move");
		}
		else
		{
			animation.play("attack");
		}
		return moveMode = newMoveMode;
	}
}