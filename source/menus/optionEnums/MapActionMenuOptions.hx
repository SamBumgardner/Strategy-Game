package menus.optionEnums;

/**
 * Enum for the different ways a unit can interact with items in its inventory.
 * 
 * IMPORTANT NOTE:
 * 	If you change or add any entries to this enum, you also need to change the 
 * 	array of strings used in MissionMenuCreator's makeGeneralActionMenu() to match, since 
 * 	this enum's entries are expected to match the order (and the IDs) assigned to 
 * 	each MenuOption in that menu.
 * 
 * @author Samuel Bumgardner
 */

@:enum
class MapActionMenuOptions
{
	public static var UNIT(default, never)			= 0;
	public static var STATUS(default, never)		= 1; 
	public static var OPTIONS(default, never)		= 2;
	public static var SUSPEND(default, never)		= 3;
	public static var END(default, never)			= 4;
}