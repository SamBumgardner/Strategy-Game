package menus.cursorMenus;

import boxes.BoxCreator;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import menus.commonBoxGraphics.InventorySlot;
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
	
	
	/**
	 * Variables to satisfy VarSizedBox interface.
	 * Specifies the qualities of the menu's box.
	 */
	public var cornerSize(default, never):Int		= 32;
	public var backgroundSize(default, never):Int	= 32;
	public var boxWidth(default, null):Int;
	public var boxHeight(default, null):Int;
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_menu__png;
	
	
	
	public var invBox1:FlxSprite;
	
	public var invBox2:FlxSprite;
	
	
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
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	public function new(?X:Float=0, ?Y:Float=0, ?subjectID:Int=0) 
	{
		super(X, Y, subjectID);
		initInventoryBoxes(X, Y);
		initInventorySlots(X, Y);
		initBasicCursor();
		initSoundAssets();
		
		addAllFlxGrps();
		
		trace(invBox1);		trace(invBox2);

		
		hide();
	}
	
	/**
	 * 
	 * @param	X
	 * @param	Y
	 */
	private function initInventoryBoxes(X:Float, Y:Float):Void
	{
		var box1LocX = 300;
		var box2LocX = 650;
		var boxY = Y;
		
		boxWidth = 300;
		boxHeight = Math.floor(itemSlotInterval * maxInventorySlots + cornerSize);
		
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		
		invBox1 = BoxCreator.createBox(boxWidth, boxHeight);
		invBox1.x = box1LocX;
		invBox1.y = boxY;
		
		
		invBox2 = BoxCreator.createBox(boxWidth, boxHeight);
		invBox2.x = box2LocX;
		invBox2.y = boxY;
		
		boxSpriteGrp = new FlxGroup();
		boxSpriteGrp.add(invBox1);
		boxSpriteGrp.add(invBox2);
	}
	
	/**
	 * Depends on initInventoryBoxes being called first.
	 * @param	X
	 * @param	Y
	 */
	private function initInventorySlots(X:Float, Y:Float):Void
	{
		var newMenuOption1:MenuOption;
		var newMenuOption2:MenuOption;
		var menuOptionWidth:Float = boxWidth - cornerSize * 2;
		
		itemSlotsGrp = new FlxGroup();
		
		for (i in 0...maxInventorySlots)
		{
			var slot1X:Float = invBox1.x + cornerSize / 2;
			var slot2X:Float = invBox2.x + cornerSize / 2;
			var slotY:Float = Y + cornerSize / 2 + itemSlotInterval * i;
			var optionOffsetY:Float = 9;
			
			itemSlotsGrp.add(new InventorySlot(slot1X, slotY));
			itemSlotsGrp.add(new InventorySlot(slot2X, slotY));
			
			newMenuOption1 = new MenuOption(slot1X + cornerSize, slotY + optionOffsetY, i * 2, 
				menuOptionWidth, "", textSize);
			newMenuOption1.label.color = FlxColor.BLACK;
			menuOptionArr.push(newMenuOption1);
			
			newMenuOption2 = new MenuOption(slot2X + cornerSize, slotY + optionOffsetY, i * 2 + 1, 
				menuOptionWidth, "", textSize);
			newMenuOption2.label.color = FlxColor.BLACK;
			menuOptionArr.push(newMenuOption2);
			
			// Set up horizontal neighbors for first menu option.
			newMenuOption1.rightOption = newMenuOption2;
			newMenuOption1.leftOption = newMenuOption2;
			newMenuOption1.leftIsWrap = true;
			
			// Set up a horizontal neighbors for second menu option.
			newMenuOption2.rightOption = newMenuOption1;
			newMenuOption2.leftOption = newMenuOption1;
			newMenuOption2.rightIsWrap = true;
			
			// Connect the current menu option and the previous option as neighbors.
			if (i > 0) 
			{
				newMenuOption1.upOption = menuOptionArr[newMenuOption1.id - 2];
				menuOptionArr[newMenuOption1.id - 2].downOption = newMenuOption1;
				
				newMenuOption2.upOption = menuOptionArr[newMenuOption2.id - 2];
				menuOptionArr[newMenuOption2.id - 2].downOption = newMenuOption2;
			}
			
			// Connect the last menu option to the first menu option as neighbors.
			if (i == maxInventorySlots - 1)
			{
				menuOptionArr[0].upOption = menuOptionArr[i];
				menuOptionArr[0].upIsWrap = true;
				menuOptionArr[i].downOption = menuOptionArr[0];
				menuOptionArr[i].downIsWrap = true;
				
				menuOptionArr[1].upOption = menuOptionArr[i + 1];
				menuOptionArr[1].upIsWrap = true;
				menuOptionArr[i + 1].downOption = menuOptionArr[1];
				menuOptionArr[i + 1].downIsWrap = true;
			}
			
			// Add the current menu option to the totalFlxGrp
			optionFlxGrp.add(newMenuOption1.totalFlxGrp);
			optionFlxGrp.add(newMenuOption2.totalFlxGrp);
		}
	}
	
	/**
	 * 
	 */
	override private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(boxSpriteGrp);
		totalFlxGrp.add(itemSlotsGrp);
		totalFlxGrp.add(optionFlxGrp);
		totalFlxGrp.add(menuCursor);
	}
	
	public function setUnits(leftUnit:Unit, rightUnit:Unit):Void
	{
		selectedUnit = leftUnit;
		otherUnit = rightUnit;
	}
	
	/**
	 * NOTE: Assumes that the current state is MissionState
	 */
	public override function resetMenu():Void
	{
		refreshInventories();
		super.resetMenu();
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
	public function refreshInventories():Void
	{	
		
		if (selectedUnit == null || otherUnit == null)
		{
			trace("ERROR: setUnits() was not called before refreshInventories(), unit variables unset.");
			return;
		}
		
		for (i in 0...maxInventorySlots)
		{
			// Set up menuOptions in the first inventory
			if (i < selectedUnit.inventory.items.length)
			{
				var optionIndex = i * 2;
				
				menuOptionArr[optionIndex].label.text = selectedUnit.inventory.items[i].name;
				
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
				
				
				// Connect the current menu option and the previous option as neighbors.
				if (i > 0) 
				{
					menuOptionArr[optionIndex].upOption = menuOptionArr[optionIndex - 2];
					menuOptionArr[optionIndex - 2].downOption = menuOptionArr[optionIndex];
				}
				
				// Connect the last menu option to the first menu option as neighbors.
				if (i == selectedUnit.inventory.items.length - 1)
				{
					menuOptionArr[0].upOption = menuOptionArr[optionIndex];
					menuOptionArr[0].upIsWrap = true;
					menuOptionArr[optionIndex].downOption = menuOptionArr[0];
					menuOptionArr[optionIndex].downIsWrap = true;
				}
				
				menuOptionArr[optionIndex].reveal();
			}
			
			// Set up menuOptions in the second inventory.
			if (i < otherUnit.inventory.items.length)
			{
				var optionIndex = i * 2 + 1;
				
				menuOptionArr[optionIndex].label.text = selectedUnit.inventory.items[i].name;
				
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
				
				// Connect the current menu option and the previous option as neighbors.
				if (i > 0) 
				{
					menuOptionArr[optionIndex].upOption = menuOptionArr[optionIndex - 2];
					menuOptionArr[optionIndex - 2].downOption = menuOptionArr[optionIndex];
				}
				
				// Connect the last menu option to the first menu option as neighbors.
				if (i == selectedUnit.inventory.items.length - 1)
				{
					menuOptionArr[1].upOption = menuOptionArr[optionIndex];
					menuOptionArr[1].upIsWrap = true;
					menuOptionArr[optionIndex].downOption = menuOptionArr[1];
					menuOptionArr[optionIndex].downIsWrap = true;
				}
				
				menuOptionArr[optionIndex].reveal();
			}
		}
	}
	
	
	
	
	
	
	/**
	 * 
	 * @param	selectedItem
	 */
	public function tradeItemSelected(selectedItem:Item):Void
	{
		/*
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
		*/
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