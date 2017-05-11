package units.movement;
import units.movement.MoveID;
import units.movement.PossibleMove.NeighborDirections;

/**
 * Static extension of the MoveID type.
 * My intent when making this class was to create an easy-to-ready way for me to use a single
 * 	integer to keep track of a pair of indices to a 2-D array. This is needed by the PossibleMove
 * 	class, which needs to use a particular row/col location as a key to its place in a Map object. 
 * 
 * Typically, if I want to create a single ID from row/column information, I just store the 
 * 	information in an integer using the following forumla:
 * 		row_col_ID = row * total_columns + col
 * 	But using that all over the place in the code would hurt readability and make some of my lines
 * 		really long.
 * 
 * Ultimately, I decided to set up the MoveID typedef and this MoveIDExtender so I can store and
 * 	retrieve row/col information from a single integer in a readable format.
 * 	
 * @author Samuel Bumgardner
 */
 
class MoveIDExtender
{
	/**
	 * Number of tiles in each column of the current map.
	 * MUST be set before using this class.
	 */
	static public var numRows:Int;
	/**
	 * Number of tiles in each row of the current map.
	 * MUST be set before using this class.
	 */
	static public var numCols:Int;
	
	/**
	 * Creates a MoveID with a value determined by the specified row & col.
	 * 
	 * @param	row	The row value of the newly-created MoveID.
	 * @param	col	The column value of the newly-created MoveID.
	 * @return	A new MoveID made from the provided row and column values.
	 */
	static public function newMoveID(row:Int, col:Int):MoveID
	{
		return row * numCols + col;
	}
	
	/**
	 * Gets a MoveID's row value.
	 * 
	 * @param	moveID	MoveID object to get the row value from.
	 * @return	The index of the MoveID's row.
	 */
	static public function getRow(moveID:MoveID):Int
	{
		return Std.int(moveID / numCols);
	}
	
	/**
	 * Gets a MoveID's column value.
	 * 
	 * @param	moveID	'this' moveID object used to find the column.
	 * @return	The index of the MoveID's column. 
	 */
	static public function getCol(moveID:MoveID):Int
	{
		return moveID % numCols;
	}
	
	/**
	 * Calculates a new MoveID by taking the provided MoveID and adjusting values according
	 * 	to row offset, and column offset. Returns null if requested location was off-map.
	 * 
	 * @param	rowOffset	Number of rows the requested tile is offset from the provided tile.
	 * @param	colOffset	Number of cols the requested tile is offset from the provided tile.
	 * @return	MoveID of the requested offset, or -1 if the requested location was outside map.
	 */
	static public function getOtherByOffset(moveID:MoveID, rowOffset:Int, colOffset:Int):MoveID
	{
		var targetMoveID:MoveID = -1;
		
		var newRow = getRow(moveID) + rowOffset;
		var newCol = getCol(moveID) + colOffset;
		
		if (newRow >= 0 && newRow < numRows && newCol >= 0 && newCol < numCols)
		{
			targetMoveID = newMoveID(newRow, newCol);
		}
		
		return targetMoveID;
	}
	
	/**
	 * Finds the direction used to move from the other MoveID to this MoveID.
	 * Undefined behavior if tiles are not orthagonally adjacent.
	 * 
	 * @param	selfMoveID	The MoveID that this direction goes to.
	 * @param	otherMoveID	The MoveID that this direction originates from.
	 * @return	NeighborDirections enum entry from other MoveID to this MoveID.
	 */
	static public function getDirFromOther(selfMoveID:MoveID, otherMoveID:MoveID):
		NeighborDirections
	{
		var dirFromOtherToSelf:NeighborDirections = null;
		
		if (getRow(otherMoveID) > getRow(selfMoveID))
			dirFromOtherToSelf = NeighborDirections.UP;
		
		else if (getRow(otherMoveID) < getRow(selfMoveID))
			dirFromOtherToSelf = NeighborDirections.DOWN;
		
		else if (getCol(otherMoveID) > getCol(selfMoveID))
			dirFromOtherToSelf = NeighborDirections.LEFT;
		
		else if (getCol(otherMoveID) < getCol(selfMoveID))
			dirFromOtherToSelf = NeighborDirections.RIGHT;
		
		return dirFromOtherToSelf;
	}
	
	/**
	 * Finds the manhattan distance between a pair of moveIDs.
	 * 
	 * For (a simplified) clarification, the manhattan distance finds the number of 
	 * 	orthagonal steps taken to move from one MoveID to another.
	 * 
	 * @param	selfMoveID	'this' MoveID, the staring point for the distance calculation.
	 * @param	otherMoveID	'other' MoveID, the endpoint for the distance calculation.
	 * @return	The Manhattan distance between the two MoveIDs.
	 */
	static public function getDistFromOther(selfMoveID:MoveID, otherMoveID:MoveID):Int
	{
		return Std.int(Math.abs(getRow(selfMoveID) - getRow(otherMoveID)) + Math.abs(
			getCol(selfMoveID) - getCol(otherMoveID)));
	}
}