package menus.targetMenus;
import missions.MissionState;
import units.Unit;

/**
 * ...
 * @author Sam Bumgardner
 */
class TalkTargetMenu extends TargetMenuTemplate 
{
	public var selectedUnit:Unit;
	
	/**
	 * NOTE: NEEDS TO BE UPDATED!
	 * 
	 * This placeholder just returns false at the moment, but should do some action
	 * 	to determine if a unit can talk to anyone adjacent to them.
	 * 
	 * @param	selectedUnit
	 * @param	neighborUnit
	 * @return
	 */
	public static function talkTargetTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return false;
	}
	
	/**
	 * Identifies all valid targets within this unit's equipped item's range, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets 
	 * 	array.
	 * 
	 * Assumes that the selected unit has a HealingItem-type item equipped. 
	 * If not, unsafe casting will result in a crash.
	 * 
	 * @param	parentState
	 */
	public override function refreshTargets(parentState:MissionState):Void
	{	
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange([1], talkTargetTest);
	}
}