package menus;

import boxes.VarSizedBox;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxGraphicAsset;
import menus.commonBoxGraphics.CombatHealthBox;
import missions.MissionState;
import units.Unit;

/**
 * ...
 * @author Samuel Bumgardner
 */
class CombatMenu extends MenuTemplate 
{
	public var width(default, never):Int = 400;
	public var height(default, null):Int;
	
	public var combatHealthBox1:CombatHealthBox;
	public var combatHealthBox2:CombatHealthBox;
	
	public function new(?X:Float=0, ?Y:Float=0, ?subjectID:Int=0) 
	{
		super(X, Y, subjectID);
		
		// Create a pair of CombatHealthBox objects
		combatHealthBox1 = new CombatHealthBox(X, Y);
		combatHealthBox2 = new CombatHealthBox(combatHealthBox1.boxSprite.x + 
			combatHealthBox1.boxWidth, Y);
		
		totalFlxGrp.add(combatHealthBox1.totalFlxGroup);
		totalFlxGrp.add(combatHealthBox2.totalFlxGroup);
		
		height = combatHealthBox1.boxHeight;
		
		hide();
	}
	
	public function setUnits(attacker:Unit, defender:Unit):Void
	{
		combatHealthBox1.setUnit(attacker);
		combatHealthBox2.setUnit(defender);
		// Set up combat variables, get numeric versions of needed derived statistics.
	}
	
	public function beginCombat():Void
	{
		// Start a series of timed events. Initiator attacks, defender counterattacks, etc.
	}
	
	public function continueCombat(whoseTurn:Int):Void
	{
		// I think this one is the meat of the combat logic. 
		// maybe. Might need some other name for it. Starts next attack, checks for death, etc.
		
	}
	
	/**
	 * This breaks the rules I set for the game's design:
	 * 	An individual menu should not interact with the missionState directly.
	 */
	private function combatFinished():Void
	{
		var missionState:MissionState = cast FlxG.state;
		
		// Should transfer controll back to the mapcursor, like all menus getting closed.
		//missionState.combatFinished();
	}
	
	// Call CombatHealthBox updates
	// Decide if the next phase of combat is ready to begin.
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		combatHealthBox1.update(elapsed);
		combatHealthBox2.update(elapsed);
	}
}