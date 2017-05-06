package units.items;

import units.Unit;

using flixel.util.FlxArrayUtil;
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
	
	public function new(itemName:String, rangeArr:Array<Int>, type:ItemTypes) 
	{
		name = itemName;
		ranges = rangeArr;
		itemType = type;
	}
	
	public function insertIntoInv(targetInv:Inventory, targetIndex:Int)
	{
		targetInv.items[targetIndex] = this;
		this.invIndex = targetIndex;
		this.inventory = targetInv;
		
		if (!targetInv.owner.canEquipItem(this))
		{
			// If this item is not equippable, remove its index from any equippable index arrays.
			targetInv.weaponIndices.fastSplice(targetInv.weaponIndices.indexOf(targetIndex));
		}
	}
	
	public function use(usingUnit:Unit, targetUnit:Unit)
	{
		
	}
}