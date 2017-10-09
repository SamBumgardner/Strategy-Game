package menus.cursorMenus;

import boxes.ResizableBox;
import boxes.VarSizedBox;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import menus.commonBoxGraphics.InventorySlot;
import units.items.Inventory;
import utilities.LogicalContainer;
import utilities.LogicalContainerNester;

/**
 * ...
 * @author Sam Bumgardner
 */
class InventoryBox implements VarSizedBox implements LogicalContainerNester
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
	
	/**
	 * Object that contains a set of sprites that can be used as a resizable box.
	 * Call this object's public functions to do any resizing or interactions with
	 *  the box.
	 */
	public var resizableBox:ResizableBox;
	
	
	/**
	 * Variable for keeping track of the menu's background box FlxSprite.
	 */
	public var boxSpriteGrp:FlxGroup;

	/**
	 * 
	 */
	public var itemSlotsGrp:FlxGroup;
	
	public var menuOptionArr(default, null):Array<MenuOption>;
	
	/**
	 * 
	 */
	public var optionFlxGrp:FlxGroup = new FlxGroup();
	
	
	/**
	 * 
	 */
	public var totalFlxGrp:FlxGroup = new FlxGroup();
	
	/**
	 * 
	 */
	public var trackedInventory(default, set):Inventory;
	
	/**
	 * x & y coordinates that all menu components should be positioned relative to.
	 * Can be changed by external entities using setPos().
	 */
	public var x(default, null):Float;
	public var y(default, null):Float;
	
	/**
	 * Array of logical containers that will need logical position updates when this object's
	 *  logical position updates.
	 */
	public var nestedContainers(null, null):Array<LogicalContainer> = new Array<LogicalContainer>();
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////

	public function new(?X:Float=0, ?Y:Float=0) 
	{
		initMenuBox(X, Y);
		initInventorySlots(X, Y);
		addAllFlxGrps();
	}
	
	/**
	 * Creates variable sized box sprite that sits behind inventory menu options.
	 * 
	 * Is also responsible for creating and populating the boxSpriteGrp FlxGroup.
	 * 
	 * @param	X				The desired x position of the menu.
	 * @param	Y				The desired y position of the menu.
	 * @param	maxTextWidth	The width of the largest MenuOption's label.
	 */
	private function initMenuBox(X:Float, Y:Float):Void
	{
		boxWidth = 300;
		boxHeight = Math.floor(itemSlotInterval * maxInventorySlots + cornerSize);
		
		resizableBox = new ResizableBox(X, Y, boxWidth, boxHeight, boxSpriteSheet, 
			cornerSize, backgroundSize);
		
		boxSpriteGrp = resizableBox.totalFlxGrp;
	}
	
	private function initInventorySlots(X:Float, Y:Float):Void
	{
		menuOptionArr = new Array<MenuOption>();
		var newMenuOption:MenuOption;
		var menuOptionWidth:Float = boxWidth - cornerSize * 2;
		
		itemSlotsGrp = new FlxGroup();
		
		for (i in 0...maxInventorySlots)
		{
			var slotX:Float = X + cornerSize / 2;
			
			#if !html5
			// Default slot positioning data for non-html5 targets.
			
			var slotY:Float = Y + cornerSize / 2 + itemSlotInterval * i;
			var optionOffsetY:Float = 9;
			
			#else
			
			// Item slot offsets are different on html5, due to needing a different,
			// 	alpha-less item slot box graphic.
			
			var slotY:Float = Y + cornerSize / 2 + itemSlotInterval * i + 6;
			var optionOffsetY:Float = 3;
			
			#end
			
			
			itemSlotsGrp.add(new InventorySlot(slotX, slotY));
			
			newMenuOption = new MenuOption(slotX + cornerSize, slotY + optionOffsetY, i, 
				menuOptionWidth, "", textSize);
			newMenuOption.label.color = FlxColor.BLACK;
			
			#if html5
			// For some reason, these menuOption cursor positions end up being 10 too small
			// 	on the html5 target.
			newMenuOption.moveCursorPos(0, 10);
			#end
			
			menuOptionArr.push(newMenuOption);
			
			// Connect the current menu option and the previous option as neighbors.
			if (i > 0) 
			{
				newMenuOption.upOption = menuOptionArr[i - 1];
				menuOptionArr[i - 1].downOption = newMenuOption;
			}
			
			// Connect the last menu option to the first menu option as neighbors.
			if (i == maxInventorySlots - 1)
			{
				menuOptionArr[0].upOption = menuOptionArr[i];
				menuOptionArr[0].upIsWrap = true;
				menuOptionArr[i].downOption = menuOptionArr[0];
				menuOptionArr[i].downIsWrap = true;
			}
			
			// Add the current menu option to the totalFlxGrp
			optionFlxGrp.add(newMenuOption.totalFlxGrp);
		}
	}
	
	private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(boxSpriteGrp);
		totalFlxGrp.add(itemSlotsGrp);
		totalFlxGrp.add(optionFlxGrp);
	}
	
	
	/**
	 * Public function for changing the position of the box and all of its components.
	 * 
	 * @param	newX	The box's new x value.
	 * @param	newY	The box's new y value.
	 */
	public function setPos(newX:Float, newY:Float):Void
	{
		var xDiff:Float = newX - x;
		var yDiff:Float = newY - y;
		
		x = newX;
		y = newY;
		
		totalFlxGrp.forEach(moveObject.bind(_, xDiff, yDiff), true);
	}
	
	/**
	 * Helper function used by setPos().
	 * Is passed as the argument into an FlxGroup's forEach() to change the x values of all
	 * 	sprites in the box's totalFlxGrp. 
	 * Because totalFlxGroup holds objects of type FlxBasic, the function has to test that the 
	 * 	"targetSprite" FlxBasic object is actually an FlxObject (or something that inherits 
	 * 	from it) so it has an x & y component to change.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 * @param	dX				The amount the targetObject's x should change by.
	 * @param	dY				The amount the targetObject's y should change by.
	 */
	private function moveObject(targetObject:FlxBasic, dX:Float, dY:Float):Void
	{
		if (Std.is(targetObject, FlxObject))
		{
			(cast targetObject).x += dX;
			(cast targetObject).y += dY;
		}
	}
	
	/**
	 * Function to satisfy LogicalContainerNester interface.
	 * Is used to update just this containers overall logical position without changing any
	 *  sprite positions. Needed when something composing this updates all sprite positions
	 *  itself, then needs to update container logical positions to match.
	 * 
	 * @param	diffX	The amount to change this container's logical X position by.
	 * @param	diffY	The amount to change this container's logical Y position by.
	 */
	public function updateLogicalPos(xDiff:Float, yDiff:Float):Void
	{
		x += xDiff;
		y += yDiff;
		
		for (logicalContainer in nestedContainers) 
		{
			logicalContainer.updateLogicalPos(xDiff, yDiff);
		}
	}
	
	public function set_trackedInventory(newInv:Inventory):Inventory
	{
		trackedInventory = newInv;
		refreshDisplay();
		return trackedInventory;
	}
	
	public function refreshDisplay():Void
	{
		if (trackedInventory != null)
		{
			for (i in 0...maxInventorySlots)
			{
				if (i < trackedInventory.items.length)
				{
					menuOptionArr[i].label.text = trackedInventory.items[i].name;
					
					
					// Connect the current menu option and the previous option as neighbors.
					if (i > 0) 
					{
						menuOptionArr[i].upOption = menuOptionArr[i - 1];
						menuOptionArr[i].downIsWrap = false;
						menuOptionArr[i - 1].downOption = menuOptionArr[i];
					}
					
					// Connect the last menu option to the first menu option as neighbors.
					if (i == trackedInventory.items.length - 1)
					{
						menuOptionArr[0].upOption = menuOptionArr[i];
						menuOptionArr[0].upIsWrap = true;
						menuOptionArr[i].downOption = menuOptionArr[0];
						menuOptionArr[i].downIsWrap = true;
					}
					
					itemSlotsGrp.members[i].visible = true;
					menuOptionArr[i].reveal();
				}
				else // Deactivate other item slots.
				{
					itemSlotsGrp.members[i].visible = false;
					menuOptionArr[i].hide();
				}
			}
		}
		boxHeight = Math.floor(itemSlotInterval * Math.max(trackedInventory.items.length, 1) + cornerSize);
		resizableBox.resize(boxWidth, boxHeight);
	}
}