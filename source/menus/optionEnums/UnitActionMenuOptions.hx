package menus.optionEnums;

/**
 * Enum for the different actions a unit may be able to perform after movement.
 * 
 * IMPORTANT NOTE:
 * 	If you change or add any entries to this enum, you also need to change the 
 * 	array of strings used in MissionMenuCreator's makeActionMenu() to match, since 
 * 	this enum's entries are expected to match the order (and the IDs) assigned to 
 * 	each MenuOption in the game's unit menu.
 * 
 * @author Samuel Bumgardner
 */

@:enum
class UnitActionMenuOptions
{
	public static var ATTACK(default, never)		= 0;
	public static var HEAL(default, never)			= 1; 
	public static var TALK(default, never)			= 2;
	public static var RESCUE(default, never)		= 3;
	public static var TAKE(default, never)			= 4;
	public static var DROP(default, never)			= 5;
	public static var ITEM(default, never)			= 6;
	public static var TRADE(default, never)			= 7;
	public static var WAIT(default, never)			= 8;
}