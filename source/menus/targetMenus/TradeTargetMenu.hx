package menus.targetMenus;
import missions.MissionState;
import units.Unit;
import units.targeting.SimpleTargetTests;

/**
 * ...
 * @author Sam Bumgardner
 */
class TradeTargetMenu extends TargetMenuTemplate 
{
	public var selectedUnit:Unit;
	
	/**
	 * Identifies all valid targets adjacent to the selected unit, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets array.
	 * 
	 * @param	parentState
	 */
	public override function refreshTargets(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange([1], SimpleTargetTests.alliedUnitTest);
	}
}