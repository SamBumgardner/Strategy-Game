package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class Item
{
	public var ranges:Array<Int>;
	public var itemType:ItemTypes;
	
	public function new(rangeArr:Array<Int>, type:ItemTypes) 
	{
		ranges = rangeArr;
		itemType = type;
	}
	
}