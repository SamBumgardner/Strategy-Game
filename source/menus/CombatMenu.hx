package menus;

import boxes.VarSizedBox;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxGraphicAsset;
import missions.MissionState;
import units.Unit;

/**
 * ...
 * @author Samuel Bumgardner
 */
class CombatMenu extends MenuTemplate implements VarSizedBox
{

	/* INTERFACE boxes.VarSizedBox */
	
	public var boxWidth(default, null):Int;
	
	public var boxHeight(default, null):Int;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset;
	
	public var cornerSize(default, null):Int;
	
	public var backgroundSize(default, null):Int;
	
	
	public function new(?X:Float=0, ?Y:Float=0, ?subjectID:Int=0) 
	{
		super(X, Y, subjectID);
		
		// Create a pair of CombatHealthBox objects
		// Position itself appropriately.
	}
	
	public function setUnits(attacker:Unit, defender:Unit):Void
	{
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
	public function update(elapsed:Float):Void
	{
		
	}
}