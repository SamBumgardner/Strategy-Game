package menus.targetMenus;
import missions.MissionState;
import units.Unit;
import units.movement.MoveID;

/**
 * ...
 * @author Sam Bumgardner
 */
class DropTargetMenu extends TargetMenuTemplate 
{
	public var selectedUnit:Unit; 
	
	/**
	 * 
	 * @param	selectedUnit
	 * @param	neighborPos
	 * @return
	 */
	public static function dropTargetTest(selectedUnit:Unit, neighborPos:MoveID):Bool
	{
		// Need to identify if the neighborPos can hold the unit rescued by the selected unit.
		return true;
	}
	
	/**
	 * Identifies all valid drop locations adjacent to the selected unit, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets array.
	 * 
	 * @param	parentState
	 */
	public override function refreshTargets(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid MoveIDs, then cast to store as Array<OnMapEntity>
		// Currently unimplemented.
	}
}