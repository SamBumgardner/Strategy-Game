package menus.targetMenus;
import flixel.FlxG;
import missions.MissionState;
import units.Unit;
import units.targeting.SimpleTargetTests;

/**
 * A target-style menu used to select which enemy to attack.
 * 
 * @author Samuel Bumgardner
 */
class AttackTargetMenu extends TargetMenuTemplate
{
	public var selectedUnit:Unit;
	
	public override function refreshTargets(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange(
			selectedUnit.equippedWeapon.attackRanges, SimpleTargetTests.enemyUnitTest);
	}
}