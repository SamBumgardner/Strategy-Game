package menus.targetMenus;
import missions.MissionState;
import units.Unit;

/**
 * ...
 * @author Sam Bumgardner
 */
class RescueTargetMenu extends TargetMenuTemplate 
{
	public var selectedUnit:Unit;
	
	/**
	 * 
	 * @param	selectedUnit
	 * @param	neighborUnit
	 * @return
	 */
	public static function rescueTargetTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit.teamID == neighborUnit.teamID 
			&& selectedUnit.carry <= neighborUnit.weight;
	}
	
	/**
	 * Identifies all valid rescue targets adjacent to the selected unit, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets array.
	 * 
	 * @param	parentState
	 */
	public override function refreshTargets(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange(
			[1], rescueTargetTest);
	}
}