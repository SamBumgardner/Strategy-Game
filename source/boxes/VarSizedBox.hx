package boxes;
import flixel.system.FlxAssets.FlxGraphicAsset;

/**
 * Interface for use by any class that uses a box created by BoxCreator.
 * Declares a set of variables needed to interact with the BoxCreator static functions.
 * 
 * @author Samuel Bumgardner
 */
interface VarSizedBox 
{
	public var boxWidth(default, null):Int;
	public var boxHeight(default, null):Int;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset;
	public var cornerSize(default, null):Int;
	public var backgroundSize(default, null):Int;
}