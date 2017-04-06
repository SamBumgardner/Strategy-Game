package menus.targetMenus;
import flixel.FlxG;
import missions.MissionState;
import units.Unit;
import units.targeting.SimpleTargetTests;

/**
 * A target-style menu used to select which ally to heal.
 * 
 * @author Samuel Bumgardner
 */
class HealTargetMenu extends TargetMenuTemplate
{
	public var selectedUnit:Unit;
	
	/**
	 * Identifies all valid targets within this unit's equipped item's range, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets array.
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
		possibleTargets = cast parentState.getValidUnitsInRange(
			(cast selectedUnit.equippedItem).healRanges, SimpleTargetTests.alliedUnitTest);
	}
}