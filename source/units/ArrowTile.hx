package units;

import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;

using units.MoveIDExtender;

/**
 * Extension of FlxSprite used to draw arrows that indicate the path of unit movement.
 * It uses a number of single-frame animations to display the different types of 
 * 	arrow-line segments that may need to be displayed along the movement path.
 * 
 * Used in UnitManager.
 * 
 * NOTE:
 * 	The naming scheme for the animations uses the following format:
 * 
 * 		"direction_used_to_reach_here" + "_" + "direction_used_to_leave_here"
 * 
 * 	so a corner that comes from the bottom of the tile, then exits through the left would be
 * 		named:
 * 
 * 		"up_left"
 * 
 * 	This allows the game to programmatically determine what animation should be played for
 * 		a segment of the unit path without too much difficulty.
 * 
 * @author Samuel Bumgardner
 */
class ArrowTile extends FlxSprite
{
	/**
	 * The size of the tiles used in the game's maps.
	 */
	public var tileSize(default, never):Int = 64;
	
	/**
	 * Tracks the current position. Uses the set_moveID method to automatically update its
	 * 	x/y variables whenever its moveID is changed.
	 */
	public var moveID(default, set):MoveID = 0;
	
	/**
	 * Initializer.
	 */
	public function new() 
	{
		super(0, 0);
		moveID = 0;
		
		loadGraphic(AssetPaths.arrow_sheet__png, true, 64, 64);
		
		// Vertical line segments
		animation.add("up_up", [0], 1, false);
		animation.add("down_down", [0], 1, false, true);
		
		// Horizontal line segments
		animation.add("right_right", [1], 1, false);
		animation.add("left_left", [1], 1, false, false, true);
		
		// Vertical arrow ends
		animation.add("up", [2], 1, false);
		animation.add("down", [2], 1, false, true, true);
		
		// Horizontal arrow ends
		animation.add("left", [3], 1, false, false, true);
		animation.add("right", [3], 1, false, true);
		
		// Corner segments with the light edge on outside of corner
		animation.add("up_right", [4], 1, false);
		animation.add("right_down", [4], 1, false, true);
		animation.add("down_left", [4], 1, false, true, true);
		animation.add("left_up", [4], 1, false, false, true);
		
		// Corner segments with the light edge on inside of corner
		animation.add("left_down", [5], 1, false);
		animation.add("down_right", [5], 1, false, false, true);
		animation.add("right_up", [5], 1, false, true, true);
		animation.add("up_left", [5], 1, false, true);
		
		active = false;
	}
	
	/**
	 * Setter method for the moveID property, is automatically called when moveID changes.
	 * 
	 * Changes x & y values to match the new MoveID's col & row info in addition to 
	 * 	setting the value of moveID.
	 * 
	 * @param	newMoveID	The new MoveID that this ArrowTile should use.
	 * @return	The ArrowTile's new MoveID value.
	 */
	public function set_moveID(newMoveID:MoveID):MoveID
	{
		x = newMoveID.getCol() * tileSize;
		y = newMoveID.getRow() * tileSize;
		return moveID = newMoveID;
	}
}