package units;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import observerPattern.Observed;
import observerPattern.Subject;
import units.items.EquippableItem;
import units.items.Inventory;
import units.items.Item;
import units.items.Item;
import units.items.WeaponItem;
import units.movement.MoveID;
import units.movement.PossibleMove;
import utilities.OnMapEntity;

using units.movement.MoveIDExtender;

/**
 * Needs to have the following:
 * 
 * 	Name
 * 	Level & statistics
 * 		health
 * 		energy
 * 
 * 		strength
 * 		agility
 * 		skill
 * 		defense
 * 		
 * 		intelligence
 * 		presence
 * 		will
 * 
 * 		carry
 * 		weight
 * 
 * 		Move amount
 * 		Move type
 * 
 * 		accuracy rating
 * 		expected damage
 * 		evasion rating
 * 		critical hit cost
 * 		critical hit damage
 * 		
 * 		
 * 		Current level
 * 		Current experience
 * 	Inventory - compose an inventory class inside this one.
 * 	Art assets - idle anim, hover anim, movement in each cardinal direction.
 * 		Also have character portrait?
 * 	
 * 	Hidden information:
 * 		Resolve level/exp
 * 		stat points to be earned next level up (earned by fighting enemies)
 * 
 * 	Path of movement (array of ints from direction enum)
 * 
 * Functions:
 * 	
 * 	add direction to end of movement path
 * 	replace path with new set of directions
 * 	Move along path
 * 
 * 	change health
 * 
 * 	Tick all stat changes down by 1
 * 
 * 	Attack in a direction. (does the little movement and boops over) reduces weapon durability
 * 
 * 	range of longest-range weapon. Needs to be updated after any item is removed or added to inventory.
 * 		May need to specified in an array, since some weapons have 1-2 range.
 * 
 * 	equip a weapon (involves updating derived stats and rearranging inventory)
 * 
 * @author Samuel Bumgardner
 */
class Unit extends FlxSprite implements Observed implements OnMapEntity
{
	public var spriteHeight(default, never):Int = 96;
	public var spriteWidth(default, never):Int = 128;
	
	public var tileSize(default, never):Int = 64;
	
	
	public var name(default, null):String;
	
	public var level(default, null):String;
	public var exp:Int;
	
	public var energy(default, null):Int;
	
	public var strength(default, null):Int;
	public var agility(default, null):Int;
	public var skill(default, null):Int;
	public var defense(default, null):Int;
	
	public var intel(default, null):Int;
	public var will(default, null):Int;
	public var presence(default, null):Int;
	
	public var carry(default, null):Int;
	public var weight(default, null):Int;
	
	public var move(default, null):Int;
	public var moveType(default, null):Int;
	
	// Derived statistics, 
	
	public var accuracy(default, null):Int;
	public var evade(default, null):Int;
	public var attackCost(default, null):Int;
	public var attackDamage(default, null):Int;
	public var critCost(default, null):Int;
	public var critDamage(default, null):Int;
	
	// Inventory
	
	public var inventory(default, null):Inventory;
	
	// List of integer ranges this unit can attack from, based on contents of inventory.
	public var attackRanges:Array<Int>;
	
	// List of integer ranges this unit can heal, based on contents of inventory.
	public var healRanges:Array<Int>;
	
	public var equippedItem:EquippableItem;
	
	
	// Rescued info
	
	public var rescuedUnit:Unit;
	
	//
	
	private var statChangeArr:Array<StatChange>;
	
	//
	
	public var mapPos:MoveID;
	
	//
	
	public var preMoveMapPos:MoveID;
	
	
	//
	
	public var subject:Subject;
	
	
	//
	
	public var canAct:Bool;
	
	/**
	 * 
	 */
	public var team(default, null):TeamType;
	
	/**
	 * The integer used to identify which group of units this unit is "friendly" toward.
	 */
	public var teamID(default, null):TeamID;
	
	/**
	 * 
	 */
	public var moveTiles:Map<MoveID, PossibleMove>;
	
	/**
	 * 
	 */
	public var attackTiles:Map<MoveID, Bool>;
	
	
	public function new(row:Int = 0, col:Int = 0, spriteSheet:FlxGraphicAsset, ID:Int = 0,
		teamP:TeamType) 
	{
		super(col * tileSize, row * tileSize);
		
		offset.x = 32;
		offset.y = 32;
		
		loadGraphic(spriteSheet, true, spriteWidth, spriteHeight);
		animation.add("up", [0, 1, 2, 3], 6);
		animation.add("down", [4, 5, 6, 7], 6);
		animation.add("left", [16, 17, 18, 17], 6);
		animation.add("right", [19, 20, 21, 20], 6);
		animation.add("hover", [9, 9, 9, 8, 10, 11, 11, 10, 10, 11, 11, 8], 10);
		animation.add("idle", [12, 13, 12, 13, 14, 15], 2);
		
		animation.play("idle");
		
		// Cannot set mapCol = X / tileSize because crashes on Neko.
		mapPos = MoveIDExtender.newMoveID(row, col);
		preMoveMapPos = mapPos;
		
		subject = new Subject(this, ID);
		
		// Very temporary code.
		canAct = true;
		team = teamP;
		if (team == ENEMY)
			teamID = ENEMY_FRIENDLY;
		else if (team == PLAYER)
			teamID = PLAYER_FRIENDLY;
		else if (team == TeamType.OTHER)
			teamID = TeamID.OTHER;
		move = 5;
		
		weight = 5;
		carry = 5;
		
		inventory = new Inventory();
		
		equippedItem = new WeaponItem();
		
		// Should actually display the union of all attack ranges in the backpack.
		// Instead, this just assumes that the equipped item is just a weapon.
		attackRanges = (cast equippedItem).attackRanges;
		healRanges = [];
	}
	
	
	public function attack(isCrit:Bool):Int
	{
		var damage;
		if (isCrit)
		{
			energy -= critCost;
			damage = critDamage;
		}
		else
		{
			energy -= attackCost;
			damage = attackDamage;
		}
		
		return damage;
	}
	
	public function dodge(enemyAccuracy:Int):Void
	{
		
	}
	
	public function defend(takeDamage:Int):Int
	{
		return takeDamage;
	}
	
	public function startTurn():Void
	{
		
	}
	
	public function endTurn():Void
	{
		
	}
	
	public function addNewStatChange():Void
	{
		
	}
	
	/**
	 * Targeted end stat change by ID.
	 * returns true if successful.
	 * @param	targetID
	 * @return
	 */
	public function endStatChange(targetID):Bool
	{
		for (statChange in statChangeArr)
		{
			if (statChange.id == targetID)
			{
				statChange.end();
				break;
			}
		}
		return true;
	}
	
	/**
	 * Clears all stat change objects, ignoring their normal "ended" behavior.
	 */
	public function clearStatChanges():Void
	{
		statChangeArr.splice(0, -1);
	}
	
	
	
	private function beginMoving(targetDirection:Int):Void
	{
		
	}
	
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
		
		if (FlxG.keys.justPressed.A)
		{
			animation.play("idle");
		}
		if (FlxG.keys.justPressed.S)
		{
			animation.play("hover");
		}
	}
	
}

enum TeamType
{
	PLAYER;
	FRIEND;
	ENEMY;
	OTHER;
}

enum TeamID
{
	PLAYER_FRIENDLY;
	ENEMY_FRIENDLY;
	OTHER;
	NONE;
}