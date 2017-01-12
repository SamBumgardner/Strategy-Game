package missions;

/**
 * Enum for different terrain types.
 * 
 * IMPORTANT NOTE:
 * 	If you change the numbers that ANY of the terrain types equal, you MUST change the 
 * 	level properties of ALL levels that use that terrain type to match the terrain's new
 * 	number.
 * 	
 * 	Adding new entries is fine, but rearranging old ones means doing extra work.
 * 
 * @author Samuel Bumgardner
 */

@:enum 
class TerrainTypes 
{
	public static var NONE(default, never)			= -1;
	public static var PLAINS(default, never)		= 0;
	public static var FOREST(default, never)		= 1;
	public static var RUBBLE(default, never)		= 2;
	public static var WRECKAGE(default, never)		= 3;
	public static var LIGHT_FORT(default, never)	= 4;
	public static var HEAVY_FORT(default, never)	= 5;
	public static var RIVER(default, never)			= 6;
}