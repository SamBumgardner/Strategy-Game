package menus;

/**
 * Enum for different menu types.
 * 
 * IMPORTANT NOTE:
 * 	If you change the numbers that ANY of the menu types equal, you MUST change the 
 * 	order that menu objects are pushed into MenuManager's menu array to match, since
 * 	this enum's entries will be used to index the array to get access to particular menus.
 * 	
 * 	Adding new entries is fine, but rearranging old ones means doing extra work.
 * 
 * @author Samuel Bumgardner
 */

@:enum 
class MissionMenuTypes 
{
	public static var NONE(default, never)					= -1;
	public static var MAP_ACTION(default, never)			= 0;
	public static var UNIT_ACTION(default, never)			= 1;
	public static var UNIT_INVENTORY(default, never)		= 2;
	public static var ITEM_ACTION(default, never)			= 3;
	public static var TRADE_TARGET(default, never)			= 4;
	public static var TRADE_ACTION(default, never)			= 5;
	public static var WEAPON_SELECT(default, never)			= 6;
	public static var ATTACK_TARGET(default, never)			= 7;
	public static var HEAL_TARGET(default, never)			= 8;
	public static var TALK_TARGET(default, never)			= 9;
	public static var RESCUE_TARGET(default, never)			= 10;
	public static var TAKE_TARGET(default, never)			= 11;
	public static var DROP_TARGET(default, never)			= 12;
	
	public static var NUM_OF_MENUS(default, never)			= 13;
}