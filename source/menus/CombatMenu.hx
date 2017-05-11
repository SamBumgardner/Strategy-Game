package menus;

import boxes.VarSizedBox;
import flixel.FlxG;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxTimer;
import menus.commonBoxGraphics.CombatHealthBox;
import missions.MissionState;
import observerPattern.eventSystem.EventTypes;
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
	
	private var originalAttacker:Unit;
	private var originalDefender:Unit;
	
	private var combatRound:Int;
	private var nextTurn:CombatRoles;
	
	private var timeBetweenTurns:Float = .75;
	private var turnTimer:FlxTimer;
	
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
		
		turnTimer = new FlxTimer();
		
		hide();
	}
	
	public function setUnits(attacker:Unit, defender:Unit):Void
	{
		originalAttacker = attacker;
		originalDefender = defender;
		
		combatHealthBox1.setUnit(attacker);
		combatHealthBox2.setUnit(defender);
	}
	
	public function beginCombat():Void
	{
		combatRound = 0;
		nextTurn = CombatRoles.ATTACKER;
		
		turnTimer.start(timeBetweenTurns, continueCombat);
		// Start a series of timed events. Initiator attacks, defender counterattacks, etc.
	}
	
	public function continueCombat(combatTimer:FlxTimer):Void
	{
		combatRound++;
		
		var attacker:Unit = null;
		var defender:Unit = null;
		
		// Do attack logic.
		if (nextTurn == ATTACKER)
		{
			attacker = originalAttacker;
			defender = originalDefender;
		}
		else if (nextTurn == DEFENDER)
		{
			attacker = originalDefender;
			defender = originalAttacker;
		}
		
		attacker.attackAnimate(defender.mapPos);
		
		var hitRoll:Int = Math.floor((FlxG.random.int(1, 100) + FlxG.random.int(1, 100)) / 2);
		var critRoll:Int = FlxG.random.int(1, 100);
		
		if (hitRoll <= attacker.accuracy - defender.evade)
		{
			var totalDamage:Float = Math.max(attacker.attackDamage - defender.defense, 0);
			
			// Check for critical damage
			if (critRoll <= attacker.critChance - defender.dodge)
			{
				// Crit occurred, do x3 damage.
				totalDamage *= 3;
				
				// Do special crit effects.
				FlxG.camera.shake(0.01, 0.2);
			}
			else 
			{
				// Do normal damage, so no change needed.
				// Play normal damage sound effect.
			}
			defender.hurt(totalDamage);
		}
		else
		{
			// Do defender dodge movement.
		}
		
		if (defender.health == 0)
		{
			combatFinished();
			return;
		}
		
		
		// Before the second round, just swap attackers so both get a turn.
		if (combatRound < 2)
		{
			if (nextTurn == DEFENDER)
			{
				nextTurn = ATTACKER;
			}
			else
			{
				nextTurn = DEFENDER;
			}
			
			turnTimer.start(timeBetweenTurns, continueCombat);
		}
		// If both sides have attacked...
		else if (combatRound == 2)
		{
			//Figure out if a third round should occur, and if so, who is attacking.
			
			if (attacker.attackSpeed >= defender.attackSpeed + 4)
			{
				// Current attacker gets a follow-up.
				turnTimer.start(timeBetweenTurns, continueCombat);
			}
			else if (defender.attackSpeed >= attacker.attackSpeed + 4)
			{
				// Current defender gets a follow-up.
				
				// Swap next turn, then move on to next round.
				if (nextTurn == DEFENDER)
				{
					nextTurn = ATTACKER;
				}
				else
				{
					nextTurn = DEFENDER;
				}
				
				turnTimer.start(timeBetweenTurns, continueCombat);
			}
			else
			{
				combatFinished();
			}
		}
		else
		{
			combatFinished();
		}
	}
	
	private function combatFinished():Void
	{
		turnTimer.start(timeBetweenTurns * 3, 
		function(timer:FlxTimer){subject.notify(EventTypes.CONFIRM); });
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

enum CombatRoles
{
	ATTACKER;
	DEFENDER;
}