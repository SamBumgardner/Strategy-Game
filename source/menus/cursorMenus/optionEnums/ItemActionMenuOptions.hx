package menus.cursorMenus.optionEnums;

/**
 * Enum for the different ways a unit can interact with items in its inventory.
 * 
 * IMPORTANT NOTE:
 * 	If you change or add any entries to this enum, you also need to change the 
 * 	array of strings used in MissionMenuCreator's makeItemActionMenu() to match, since 
 * 	this enum's entries are expected to match the order (and the IDs) assigned to 
 * 	each MenuOption in that menu.
 * 
 * @author Samuel Bumgardner
 */

@:enum
class ItemActionMenuOptions
{
	public static var EQUIP(default, never)			= 0;
	public static var USE(default, never)			= 1; 
	public static var TRADE(default, never)			= 2;
	public static var DISCARD(default, never)		= 3;
}