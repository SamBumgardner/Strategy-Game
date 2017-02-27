package units;

/**
 * Class that details a stat change affecting a character.
 * 
 * Includes stat change info
 * 
 * Duration: -1 means lasts until something external removes it.
 * 
 * ID - taken from statChangeTypes enum. 
 * 	example types:
 * 		item-based change.
 * 		overloaded change.
 * 
 * Perhaps have post-stat-change function, called when the state ends.
 * 
 * @author Samuel Bumgardner
 */
class StatChange
{

	public var id(default, null):Int;
	public var end(default, null):Void->Void;
	
	public function new() 
	{
		
	}
	
}