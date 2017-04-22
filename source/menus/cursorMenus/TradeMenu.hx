package menus.cursorMenus;

/**
 * ...
 * @author Samuel Bumgardner
 */
class TradeMenu extends CursorMenuTemplate
{

	public function new(?X:Float=0, ?Y:Float=0, ?subjectID:Int=0) 
	{
		super(X, Y, subjectID);
		
		
		
	}
	
	
	/**
	 * 
	 * @param	selectedItem
	 */
	public function tradeItemSelected(selectedItem:Item):Void
	{
		var notSelectedInv:Inventory;
		if (selectedItem.inventory == unitManager.selectedUnit.inventory)
		{
			notSelectedInv = unitManager.targetUnit.inventory;
		}
		else
		{
			notSelectedInv = unitManager.selectedUnit.inventory;
		}
		
		notSelectedInv.addDummyItem();
	}
	
	/**
	 * Swaps the positional data of two different items.
	 * 
	 * @param	item1
	 * @param	item2
	 */
	public function tradeItems(item1:Item, item2:Item):Void
	{
		var index1:Int = item1.invIndex;
		var inv1:Inventory = item1.inventory;
		
		item1.invIndex = item2.invIndex;
		item1.inventory = item2.inventory;
		
		item1.inventory.items[item1.invIndex] = item1;
		
		
		item2.invIndex = index1;
		item2.inventory = inv1;
		
		item2.inventory.items[item2.invIndex] = item2;
	}
	
	public function tradeItemCleanup(inventory1:Inventory, inventory2:Inventory):Void
	{
		inventory1.removeDummyItem();
		inventory2.removeDummyItem();
	}
	
	/**
	 * 
	 * @param	otherUnit
	 */
	public function finalizeTrades():Void
	{
		// Loop through items in both inventories, change owner variable to match owner of inventory.
		// If any items changed owners, then set selected unit's canAct to false.
		
	}
}