package units;

using units.MoveIDExtender;

/**
 * This class contains information about the tiles of the mission's map. This includes
 * 	the optimal movement cost to reach this tile, and what direction the unit 
 * 	would use to move into this tile when following the optimal path to it.
 * 
 * To see this in action, check out the following sections of code:
 * 	- UnitManager's getUnitMovementRange function.
 * 	- UnitManager's arrow calculating function.
 * 	- MapCursor's selectedLocations map.
 * 	- Unit's moveTiles map.
 * And more!
 * 
 * @author Samuel Bumgardner
 */
class PossibleMove
{	
	/**
	 * The direction of movement used to enter this space when using an optimal movement path.
	 * The value START indicates that this space is the origin of the unit's movement.
	 */
	public var direction:NeighborDirections;
	
	/**
	 * Cost (in movement points) for the unit to reach this tile of the map.
	 */
	public var moveCost:Int;
	
	/**
	 * Whether this Possible move is already in the breadth-first-style processing queue. In 
	 * 	some cases, a tile may be added to the queue multiple times. If this occurs, it only
	 * 	really needs to be processed at the last point in time, and should be ignored until
	 * 	then. 
	 * 
	 * Should be 0 after it has been properly processed.
	 */
	public var numTimesInBfQueue:Int = 0;
	
	/**
	 * Tracks the row/column location of this PossibleMove. 
	 * See MoveIDExtender for usage details.
	 */
	public var moveID:MoveID;
	
	/**
	 * Initializer.
	 * 
	 * @param	dir		The direction of movement used to finish this move
	 * @param	cost	The cost in movement points to make this move
	 * @param	row		The row location of this PossibleMove
	 * @param	col		The col location of this PossibleMove
	 */
	public function new(dir:NeighborDirections, cost:Int, row:Int, col:Int) 
	{
		direction = dir;
		moveCost = cost;
		moveID = MoveIDExtender.newMoveID(row, col);
	}
}

enum NeighborDirections
{
	UP;
	RIGHT;
	DOWN;
	LEFT;
	
	UP_LEFT;
	UP_RIGHT;
	DOWN_LEFT;
	DOWN_RIGHT;
	
	START;
}