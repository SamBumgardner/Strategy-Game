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
class InventoryMenu extends CursorMenuTemplate implements VarSizedBox
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
	private var selectedUnit:Unit;
	
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
		refreshMenuOptions(cast FlxG.state);
		super.resetMenu();
	}
	
	/**
	 * A lighter version of the reset() function, which should be called whenever the
	 * 	item menu's contents should be updated to match the current selected unit's 
	 * 	inventory.
	 * 
	 * @param	parentState
	 */
	public function refreshMenuOptions(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		inventoryBox.trackedInventory = selectedUnit.inventory;
		
	}
	
	override private function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void
	{
		super.moveResponse(vertMove, horizMove, heldMove);
		hoveredItemIndex = currMenuOption.id;
	}
	
	public function rememberHoveredItem():Void
	{
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