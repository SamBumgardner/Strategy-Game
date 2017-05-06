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
	private var dummyItem:Item;
	
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
			dummyItem = new Item([], ItemTypes.DUMMY);
		}
		maxSize = 7;
	}
	
	public function addItemToEnd(newItem:Item):Void
	{
		items.push(newItem);
		newItem.insertIntoInv(this, items.length - 1);
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
			addItemToEnd(dummyItem);
		}
	}
	
	/**
	 * Cleans up dummy item from the inventory. Should be called after items are exchanged.
	 */
	public function removeDummyItem():Void
	{
		var invLength:Int = items.length;
		var dummyIndex:Int = -1;
		for (i in 0...invLength)
		{
			var currIndex = invLength - (i + 1);
			if (items[currIndex].itemType == ItemTypes.DUMMY)
			{
				items.splice(currIndex, 1);
				dummyIndex = currIndex;
				break;
			}
		}
		
		if (dummyIndex != -1)
		{
			for (i in dummyIndex...items.length)
			{
				items[i].invIndex = i;
			}
		}
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
		
		if (items.length != owner.heldItemCount)
		{
			changeOccurred = true;
			owner.heldItemCount = items.length;
		}
		
		owner.itemsHaveChanged = changeOccurred;
		
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
	
	public function updateEquippableIndices():Void
	{
		// Clear current weaponIndices array
		weaponIndices.splice(0, weaponIndices.length);
		
		for (i in 0...items.length)
		{
			if (items[i].itemType == ItemTypes.WEAPON && owner.canEquipItem(items[i]))
			{
				weaponIndices.push(i);
			}
		}
	}
	
	/**
	 * Swaps the positional data of two different items.
	 * 
	 * @param	item1
	 * @param	item2
	 */
	static public function tradeItems(item1:Item, item2:Item):Void
	{
		var index1:Int = item1.invIndex;
		var inv1:Inventory = item1.inventory;
		
		item1.insertIntoInv(item2.inventory, item2.invIndex);
		item2.insertIntoInv(inv1, index1);
	}
}