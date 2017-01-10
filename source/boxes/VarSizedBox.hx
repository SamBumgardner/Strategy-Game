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
	public var boxWidth:Int;
	public var boxHeight:Int;
	
	public var boxSpriteSheet:FlxGraphicAsset;
	public var cornerSize:Int;
	public var backgroundSize:Int;
}