package units.movement;
import units.Unit.TeamID;

/**
 * Small class to wrap up data about a change to a particular tile of the map. 
 * Indicates a tile location, whether that tile was opened or closed, and the team 
 * 	affiliation of the opening/closing event.
 * 
 * Used in UnitManager to track the changes that a unit should consider when recalculating
 * 	its movement range.
 * 
 * @author Samuel Bumgardner
 */
class TileChange
{
	/**
	 * Indicates the location on the map that this TileChange references.
	 */
	public var moveID(default, null):MoveID;
	
	/**
	 * If true, then the change resulted in the tile opening.
	 * If false, then the change resulted in the tile closing.
	 */
	public var wasOpened(default, null):Bool;
	
	/**
	 * The teamID of the unit that caused the change.
	 * Units can ignore changes made by their own team.
	 * Changes by the "NONE" team must be observed by all units.
	 */
	public var causedBy(default, null):TeamID;
	
	/**
	 * Array of integers that indicate which unitIDs have processed TileChanges up to
	 * 	and including this tile, but no farther. Used in UnitManager when attempting to
	 * 	remove TileChanges that have been processed by all units, and thus no longer need
	 * 	to be remembered.
	 */
	public var unitsHaveProcessed:Array<Int>;
	
	/**
	 * Initializer.
	 * 
	 * @param	tileLoc	MoveID of the tile that was changed.
	 * @param	opened	True if tile was opened, false if closed.
	 * @param	team	teamID of the unit that caused this move.
	 */
	public function new(tileLoc:MoveID, opened:Bool, team:TeamID) 
	{
		moveID = tileLoc;
		wasOpened = opened;
		causedBy = team;
		unitsHaveProcessed = new Array<Int>();
	}
	
}