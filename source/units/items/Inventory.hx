package units.items;

/**
 * Inventory for a unit
 * 
 * Needs the following functions:
 * 
 * Get total weight
 * Get array of items
 * Consume charge of item.
 * Get array of items of a certain type: i.e. find all weapons, find all staves.
 * Remove item
 * Add item
 * 
 * Move item to top of inventory
 * Replace item at target index (used during trading)
 * 
 * @author Samuel Bumgardner
 */
class Inventory
{
	/**
	 * 
	 */
	static public var dummyItem:Item;
	
	/**
	 * 
	 */
	public var maxSize:Int;
	
	/**
	 * 
	 */
	public var owner:Unit;
	

	public var items:Array<Item> = new Array<Item>();
	public var weaponIndices:Array<Int> = new Array<Int>();
	
	public function new() 
	{
		if (dummyItem == null)
		{
			dummyItem = new Item([], ItemTypes.OTHER);
		}
		
	}
	
	/**
	 * Attempts to add a "dummy" item to the inventory. 
	 * Needed when trading items so a unit can give away an item without taking
	 * 	item back in return.
	 */
	public function addDummyItem():Void
	{
		if (items.length < maxSize)
		{
			items.push(dummyItem);
		}
	}
	
	/**
	 * Cleans up dummy item from the inventory. Should be called after items are exchanged.
	 */
	public function removeDummyItem():Void
	{
		items.remove(dummyItem);
	}
	
	public function finalizeItemInfo():Bool
	{
		var changeOccurred:Bool = false;
		
		for (i in 0...items.length)
		{
			if (items[i].owner != owner)
			{
				items[i].owner = owner;
				changeOccurred = true;
			}
		}
		return changeOccurred;
	}
	
	public function updateEquippedItem():Bool
	{
		var changedEquipped:Bool = false;
		
		// TODO: do a more robust check if item is equippable.
		if (owner.equippedItem != items[0])
		{
			if (items[0].itemType == ItemTypes.WEAPON || items[0].itemType == ItemTypes.HEALING)
			{
				owner.equipItem(0);
			}
			else
			{
				owner.equippedItem = null;
			}
			
			changedEquipped = true;
		}
		
		return changedEquipped;
	}
	
	/**
	 * Swaps the positional data of two different items.
	 * 
	 * @param	item1
	 * @param	item2
	 */
	static public function tradeItems(item1:Item, item2:Item):Void
	{
		trace(item1.inventory,  item2.inventory);
		
		var index1:Int = item1.invIndex;
		var inv1:Inventory = item1.inventory;
		
		item1.invIndex = item2.invIndex;
		item1.inventory = item2.inventory;
		
		item1.inventory.items[item1.invIndex] = item1;
		
		item2.invIndex = index1;
		item2.inventory = inv1;
		
		item2.inventory.items[item2.invIndex] = item2;
	}
}