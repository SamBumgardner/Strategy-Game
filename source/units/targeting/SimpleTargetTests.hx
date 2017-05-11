package units.targeting;
import units.Unit;

/**
 * A class full of static methods for identifying targets for unit-targeting things.
 * Provides a method for each of the non-NONE entries in the TargetTypes enum.
 * @author Samuel Bumgardner
 */
class SimpleTargetTests
{

	public function new() {}
	
	/**
	 * Self-targeting only test. 
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * Make sure that range 0 is included in the range list parameter when this is passed 
	 * 	into the MissionState's (or UnitManager's) getValidUnitsInRange function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function selfUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit == neighborUnit;
	}
	
	/**
	 * Other-targeting only test.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function otherUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit != neighborUnit;
	}
	
	/**
	 * Ally-targeting only test.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function alliedUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit.teamID == neighborUnit.teamID && selectedUnit != neighborUnit;
	}
	
	/**
	 * Enemy-targeting only test.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function enemyUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit.teamID != neighborUnit.teamID;
	}
	
	/**
	 * Self- or ally-targeting test.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * Make sure that range 0 is included in the range list parameter when this is passed 
	 * 	into the MissionState's (or UnitManager's) getValidUnitsInRange function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function self_allyUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit.teamID == neighborUnit.teamID;
	}
	
	/**
	 * Self- or enemy-targeting test.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * Make sure that range 0 is included in the range list parameter when this is passed 
	 * 	into the MissionState's (or UnitManager's) getValidUnitsInRange function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function self_enemyUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return selectedUnit.teamID != neighborUnit.teamID || selectedUnit == neighborUnit;
	}
	
	/**
	 * Self- or other-targeting test. That is, any unit is valid.
	 * 
	 * Meant to be passed into the MissionState's (or UnitManager's) getValidUnitsInRange 
	 * 	function.
	 * 
	 * Make sure that range 0 is included in the range list parameter when this is passed 
	 * 	into the MissionState's (or UnitManager's) getValidUnitsInRange function.
	 * 
	 * @param	selectedUnit	The unit doing the targeting.
	 * @param	neighborUnit	The prospective target unit.
	 * @return	A boolean describing whether neighborUnit is a valid target or not.
	 */
	static public function self_otherUnitTest(selectedUnit:Unit, neighborUnit:Unit):Bool
	{
		return true;
	}
}