package units.items;

/**
 * ...
 * 
 * NOTE: Need to update documentation.
 * @author Samuel Bumgardner
 */
class Item
{
	public var ranges:Array<Int>;
	public var itemType:ItemTypes;
	public var name:String;
	
	public function new(rangeArr:Array<Int>, type:ItemTypes) 
	{
		ranges = rangeArr;
		itemType = type;
	}
	
}