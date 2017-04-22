package units.items;

import units.Unit;

/**
 * ...
 * 
 * NOTE: Need to update documentation.
 * @author Samuel Bumgardner
 */
class Item
{
	public var durability:Int;
	public var inventory:Inventory;
	public var invIndex:Int;
	public var owner:Unit;
	public var ranges:Array<Int>;
	public var itemType:ItemTypes;
	public var name:String;
	
	public function new(rangeArr:Array<Int>, type:ItemTypes) 
	{
		ranges = rangeArr;
		itemType = type;
	}
	
	public function use(usingUnit:Unit, targetUnit:Unit)
	{
		
	}
}