package menus.cursorMenus;

import boxes.BoxCreator;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import inputHandlers.ActionInputHandler.KeyIndex;
import observerPattern.eventSystem.EventTypes;
import units.Unit;
import units.items.Inventory;
import units.items.Item;

/**
 * ...
 * @author Samuel Bumgardner
 */
class TradeMenu extends CursorMenuTemplate
{

	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Maximum number of inventory slots this menu can display.
	 */
	public var maxInventorySlots(default, never):Int = 7;
	
	/**
	 * Constant variables that define the font size of the item text and the vertical interval
	 * 	between item boxes.
	 */
	private var textSize(default, never):Int = 16;
	private var itemSlotInterval(default, never):Float = 40;
	
	public var invBox1:InventoryBox;
	
	public var invBox2:InventoryBox;
	
	
	/**
	 * Variable for keeping track of the inventory boxes.
	 */
	private var boxSpriteGrp:FlxGroup;

	/**
	 * 
	 */
	private var itemSlotsGrp:FlxGroup;
	
	
	/**
	 * 
	 */
	private var selectedUnit:Unit;
	
	/**
	 * 
	 */
	private var otherUnit:Unit;
	
	/**
	 * 
	 */
	public var hoveredItemIndex:Int;
	
	/**
	 * 
	 */
	public var selectedItem:Item;
	
	/**
	 * 
	 */
	private var selectedCursor:FlxSprite;
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	public function new(?X:Float=0, ?Y:Float=0, ?subjectID:Int=0) 
	{
		super(X, Y, subjectID);
		initInventoryBoxes(X, Y);
		initBasicCursor();
		initSelectedCursor();
		initSoundAssets();
		
		addAllFlxGrps();
		
		hide();
	}
	
	/**
	 * 
	 * @param	X
	 * @param	Y
	 */
	private function initInventoryBoxes(X:Float, Y:Float):Void
	{
		menuOptionArr = new Array<MenuOption>();
		
		var box1LocX = 300;
		var box2LocX = 650;
		var boxY = Y;
		
		invBox1 = new InventoryBox(box1LocX, boxY);
		invBox2 = new InventoryBox(box2LocX, boxY);
		
		// Add menuOptions to this menu's options array in an alternating order
		for (i in 0...maxInventorySlots)
		{
			menuOptionArr.push(invBox1.menuOptionArr[i]);
			menuOptionArr.push(invBox2.menuOptionArr[i]);
			
			menuOptionArr[i].leftIsWrap = true;
			menuOptionArr[i + 1].rightIsWrap = true;
		}
		
		for (i in 0...menuOptionArr.length)
		{
			menuOptionArr[i].id = i;
			
			trace(menuOptionArr[i].id);
		}
		
		boxSpriteGrp = new FlxGroup();
		boxSpriteGrp.add(invBox1.boxSpriteGrp);
		boxSpriteGrp.add(invBox2.boxSpriteGrp);
		
		itemSlotsGrp = new FlxGroup();
		itemSlotsGrp.add(invBox1.itemSlotsGrp);
		itemSlotsGrp.add(invBox2.itemSlotsGrp);
		
		optionFlxGrp = new FlxGroup();
		optionFlxGrp.add(invBox1.optionFlxGrp);
		optionFlxGrp.add(invBox2.optionFlxGrp);
	}
	
	/**
	 * 
	 */
	private function initSelectedCursor():Void
	{
		selectedCursor = new FlxSprite(0, 0, AssetPaths.menu_cursor_simple__png);
		selectedCursor.active = false;
		selectedCursor.visible = false;
	}
	
	/**
	 * 
	 */
	override private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(boxSpriteGrp);
		totalFlxGrp.add(itemSlotsGrp);
		totalFlxGrp.add(optionFlxGrp);
		totalFlxGrp.add(selectedCursor);
		totalFlxGrp.add(menuCursor);
	}
	
	public function setUnits(leftUnit:Unit, rightUnit:Unit):Void
	{
		selectedUnit = leftUnit;
		otherUnit = rightUnit;
		
		invBox1.trackedInventory = selectedUnit.inventory;
		invBox2.trackedInventory = otherUnit.inventory;
	}
	
	/**
	 * NOTE: Assumes that the current state is MissionState
	 */
	public override function resetMenu():Void
	{
		refreshMenuOptions();
		super.resetMenu();
		selectedCursor.visible = false;
	}
	
	/**
	 * A lighter version of the reset() function, which should be called whenever the
	 * 	item menu's contents should be updated to match the current selected unit's 
	 * 	inventory.
	 * 
	 * relies on setUnits being callled ahead of time.
	 * 
	 * @param	parentState
	 */
	public function refreshMenuOptions():Void
	{	
		
		if (selectedUnit == null || otherUnit == null)
		{
			trace("ERROR: setUnits() was not called before refreshInventories(), unit variables unset.");
			return;
		}
		
		invBox1.refreshDisplay();
		invBox2.refreshDisplay();
		
		for (i in 0...maxInventorySlots)
		{
			// Set up menuOptions in the first inventory
			if (i < selectedUnit.inventory.items.length)
			{
				var optionIndex = i * 2;
				
				// Connect this menuOption horizontally.
				if (i < otherUnit.inventory.items.length)
				{
					menuOptionArr[optionIndex].rightOption = menuOptionArr[optionIndex + 1];
					menuOptionArr[optionIndex].leftOption = menuOptionArr[optionIndex + 1];
				}
				else
				{
					var targetIndex = (otherUnit.inventory.items.length - 1) * 2 + 1;
					
					menuOptionArr[optionIndex].rightOption = menuOptionArr[targetIndex];
					menuOptionArr[optionIndex].leftOption = menuOptionArr[targetIndex];
				}
			}
			
			// Set up menuOptions in the second inventory.
			if (i < otherUnit.inventory.items.length)
			{
				var optionIndex = i * 2 + 1;
				
				// Connect this menuOption horizontally.
				if (i < selectedUnit.inventory.items.length)
				{
					menuOptionArr[optionIndex].rightOption = menuOptionArr[optionIndex - 1];
					menuOptionArr[optionIndex].leftOption = menuOptionArr[optionIndex - 1];
				}
				else
				{
					var targetIndex = (otherUnit.inventory.items.length - 1) * 2;
					
					menuOptionArr[optionIndex].rightOption = menuOptionArr[targetIndex];
					menuOptionArr[optionIndex].leftOption = menuOptionArr[targetIndex];
				}
			}
		}
	}
	
	override function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void 
	{
		super.moveResponse(vertMove, horizMove, heldMove);
		trace(currMenuOption.id);
	}
	
	override public function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool):Void
	{
		if (!heldAction)
		{
			// Could also be done with a loop, but this ends up being easier to understand.
			if (pressedKeys[KeyIndex.CONFIRM])
			{
				confirmSound.play(true);
				
				if (selectedItem == null)
				{
					selectItem();
				}
				else
				{
					tradeItems();
				}
			}
			else if (pressedKeys[KeyIndex.CANCEL])
			{
				cancelSound.play(true);
				
				if (selectedItem == null)
				{
					subject.notify(EventTypes.CANCEL);
				}
				else
				{
					unselectItem();
				}
			}
			else if (pressedKeys[KeyIndex.PAINT])
			{
				subject.notify(EventTypes.PAINT);
			}
			else if (pressedKeys[KeyIndex.NEXT])
			{
				subject.notify(EventTypes.NEXT);
			}
			else if (pressedKeys[KeyIndex.INFO])
			{
				subject.notify(EventTypes.INFO);
			}
		}
	}
	
	
	
	
	/**
	 * 
	 * @param	selectedItem
	 */
	public function getItemFromOptionID():Item
	{
		var currOptionInv:Inventory;
		
		// If currSelectedOption's id is even, it's in inv1, otherwise inv2.
		if (currMenuOption.id % 2 == 0)
		{
			currOptionInv = invBox1.trackedInventory;
		}
		else
		{
			currOptionInv = invBox2.trackedInventory;
		}
		
		return currOptionInv.items[Math.floor(currMenuOption.id / 2)];
	}
	
	private function selectItem():Void
	{
		selectedCursor.x = currMenuOption.cursorPos.x;
		selectedCursor.y = currMenuOption.cursorPos.y;
		selectedCursor.visible = true;
		
		selectedItem = getItemFromOptionID();
		
		if (selectedItem.inventory == invBox1.trackedInventory)
		{
			invBox2.trackedInventory.addDummyItem();
		}
		else
		{
			invBox1.trackedInventory.addDummyItem();
		}
		
		refreshMenuOptions();
	}
	
	private function unselectItem():Void
	{
		selectedItem = null;
		
		tradeItemCleanup();
		refreshMenuOptions();
	}
	
	private function tradeItems():Void
	{
		Inventory.tradeItems(selectedItem, getItemFromOptionID());
		tradeItemCleanup();
		
		selectedItem = null;
		
		refreshMenuOptions();
	}
	
	
	public function tradeItemCleanup():Void
	{
		invBox1.trackedInventory.removeDummyItem();
		invBox2.trackedInventory.removeDummyItem();
		selectedCursor.visible = false;
	}
	
	/**
	 * 
	 */
	public function finalizeTrades():Void
	{
		// Loop through items in both inventories, change owner variable to match owner of inventory.
		// If any items changed owners, then set selected unit's canAct to false.
		var changeOccurred:Bool = false;
		
		// Finalize item changes, items exchanging inventories counts as a meaning ful change.
		changeOccurred = invBox1.trackedInventory.finalizeItemInfo() || 
			invBox2.trackedInventory.finalizeItemInfo();
		
		// Determine if either inventory has a new equipped item.
		invBox1.trackedInventory.updateEquippedItem();
		// NOTE: Changing the other target's equipped item counts as a meaningful change.
		changeOccurred = changeOccurred || invBox2.trackedInventory.updateEquippedItem();
	}
}