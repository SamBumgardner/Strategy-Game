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
}