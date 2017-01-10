package utilities;

/**
 * Interface for any object that needs to have an update function like an object from HaxeFlixel,
 * 	but does not inherit from any HaxeFlixel object.
 * 
 * @author Samuel Bumgardner
 */
interface UpdatingEntity 
{
	public var active:Bool;
	
	public function activate():Void;
	public function deactivate():Void;
	
	public function update(elapsed:Float):Void;
}