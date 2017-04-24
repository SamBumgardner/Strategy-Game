package menus;
import menus.cursorMenus.BasicMenu;
import menus.cursorMenus.InventoryMenu;
import menus.cursorMenus.ResizableBasicMenu;
import menus.cursorMenus.TradeMenu;
import menus.targetMenus.AttackTargetMenu;
import menus.targetMenus.DropTargetMenu;
import menus.targetMenus.HealTargetMenu;
import menus.targetMenus.RescueTargetMenu;
import menus.targetMenus.TakeTargetMenu;
import menus.targetMenus.TalkTargetMenu;
import menus.targetMenus.TradeTargetMenu;

/**
 * A collection of public static functions used to generate all menus
 * 	used inside the game's missions.
 * 
 * All of the menu creation logic is specified here for two reasons:
 * 
 * 	1. It makes it easy to track down how a particular menu was initialized. Instead
 * 		of having to hunt through initialization functions to see what parameters the 
 * 		trade menu was created with, you can just look here.
 * 
 * 	2. It is much more nicely condensed solution than having a bunch of class files 
 * 		just to specify the parameters for the different BasicMenus and ResizeableBasicMenus.
 * 
 * The functions below should be organized so they match the order of menus in MissionMenuTypes.
 * 	For convenience, I'll include that order here as well:
 * 
 * 		map action 
 * 		unit action
 * 		unit inventory
 * 		item action
 * 		trade target
 * 		trade action
 * 		weapon select
 * 		attack target
 * 		heal target
 * 		rescue target
 * 		take target
 * 		drop target
 * 
 * NOTE: Need to update documentation.
 * 
 * @author Samuel Bumgardner
 */
class MissionMenuCreator
{

	public function new() {}
	
	/**
	 * Creates and returns a BasicMenu with options for the different actions
	 * 	the player can take after selecting a part of the map with no unit beneath it.
	 * 
	 * The list of strings used to create the menu can also be found in enum form in the file 
	 *  MapActionMenuOptions.hx
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeMapActionMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):BasicMenu
	{
		return new BasicMenu(X, Y, ["Unit", "Status", "Options", "Suspend", "End"], ID);
	}
	
	/**
	 * Creates and returns a ResizeableBasicMenu with options for each action units can 
	 * 	perform after movement.
	 * 
	 * The list of strings used to create the menu can also be found in enum form in the file 
	 * 	ActionMenuOptions.hx
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the game's action menu.
	 */
	public static function makeUnitActionMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):ResizableBasicMenu
	{
		return new ResizableBasicMenu(X, Y, 
			["Attack", "Heal", "Talk", "Rescue", "Take", "Drop", "Item", "Trade", "Wait"], 
			ID);
	}
	
	/**
	 * Temporary placeholder, actual inventory menu will need to have functionality
	 *  beyond a normal resizable menu.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeInventoryMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):InventoryMenu
	{
		return new InventoryMenu(X, Y, ID);
	}
	
	/**
	 * Creates and returns a ResizeableBasicMenu with options for each way a unit can interact
	 * 	with an item in their inventory.
	 * 
	 * The list of strings used to create the menu can also be found in enum form in the file 
	 *  ItemMenuOptions.hx
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by item action menus.
	 */
	public static function makeItemActionMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):ResizableBasicMenu
	{
		return new ResizableBasicMenu(X, Y, ["Equip", "Use", "Trade", "Discard"], ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeTradeTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):TradeTargetMenu
	{
		return new TradeTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, should display both characters' inventories and allow
	 *  movement between each.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeTradeActionMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):TradeMenu
	{
		return new TradeMenu(X, Y, ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeAttackTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):AttackTargetMenu
	{
		return new AttackTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeHealTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):HealTargetMenu
	{
		return new HealTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeTalkTargetMenu(?X:Float = 0, ?Y:Float = 0,
		?ID:Int = 0):TalkTargetMenu
	{
		return new TalkTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeRescueTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):RescueTargetMenu
	{
		return new RescueTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeTakeTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):TakeTargetMenu
	{
		return new TakeTargetMenu(ID);
	}
	
	/**
	 * Temporary placeholder, target menus should involve a cursor highlighting the 
	 *  unit on the map rather than a normal menu structure.
	 * 
	 * @param	X	The desired X position of the newly created menu.
	 * @param	Y	The desired Y position of the newly created menu.
	 * @param	ID	The desired ID for the newly created menu.
	 * @return	A ResizeableBasicMenu with all of the options needed by the map action menu.
	 */
	public static function makeDropTargetMenu(?X:Float = 0, ?Y:Float = 0, 
		?ID:Int = 0):DropTargetMenu
	{
		return new DropTargetMenu(ID);
	}
}