package menus.cursorMenus;
import boxes.BoxCreator;
import boxes.ResizableBox;
import boxes.VarSizedBox;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import menus.commonBoxGraphics.InventorySlot;
import missions.MissionState;
import units.Unit;

/**
 * ...
 * @author Samuel Bumgardner
 */
class InventoryMenu extends CursorMenuTemplate
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 *
	 */
	private var inventoryBox:InventoryBox;
	
	/**
	 * Variable for keeping track of the menu's background box FlxSprite.
	 */
	private var boxSpriteGrp:FlxGroup;

	/**
	 * 
	 */
	private var itemSlotsGrp:FlxGroup;
	
	
	/**
	 * 
	 */
	public var selectedUnit(default, set):Unit;
	
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
		initInventoryBox(X, Y);
		initBasicCursor();
		addAllFlxGrps();
		setScrollFactors();
		hide();
	}
	
	private function initInventoryBox(X:Float, Y:Float):Void
	{
		inventoryBox = new InventoryBox(X, Y);
		menuOptionArr = inventoryBox.menuOptionArr;
	}
	
	
	override private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(inventoryBox.boxSpriteGrp);
		totalFlxGrp.add(inventoryBox.itemSlotsGrp);
		totalFlxGrp.add(inventoryBox.optionFlxGrp);
		totalFlxGrp.add(menuCursor);
	}
	
	/**
	 * NOTE: Assumes that the current state is MissionState
	 */
	public override function resetMenu():Void
	{
		inventoryBox.refreshDisplay();
		super.resetMenu();
		hoveredItemIndex = currMenuOption.id;
	}
	
	public function set_selectedUnit(newUnit:Unit):Unit
	{
		selectedUnit = newUnit;
		inventoryBox.trackedInventory = selectedUnit.inventory;
		return selectedUnit;
	}
	
	/**
	 * A lighter version of the reset() function, which should be called whenever the
	 * 	item menu's contents should be updated to match the current selected unit's 
	 * 	inventory.
	 * 
	 * @param	parentState
	 */
	public function refreshMenuOptions():Void
	{
		inventoryBox.refreshDisplay();
	}
	
	override private function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void
	{
		super.moveResponse(vertMove, horizMove, heldMove);
		hoveredItemIndex = currMenuOption.id;
	}
	
	public function rememberHoveredItem(hoveredItemID:Int):Void
	{
		hoveredItemIndex = hoveredItemID;
		
		// If the old hovered item is still an active option,
		if (menuOptionArr[hoveredItemIndex].label.visible == true)
		{
			currMenuOption.cursorExited();
			currMenuOption = menuOptionArr[hoveredItemIndex];
			currMenuOption.cursorEntered();
			
			menuCursor.setAnchor(currMenuOption.cursorPos.x, currMenuOption.cursorPos.y);
			menuCursor.jumpToAnchor();
		}
	}
}