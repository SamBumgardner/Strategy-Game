package units;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import observerPattern.Observed;
import observerPattern.Subject;
import observerPattern.eventSystem.UnitEvents;
import units.items.EquippableItem;
import units.items.Inventory;
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
 * 
 * 
 * NOTE: Need to update documentation.
 * 
 * @author Samuel Bumgardner
 */
class Unit extends FlxSprite implements Observed implements OnMapEntity
{
	public var spriteHeight(default, never):Int = 96;
	public var spriteWidth(default, never):Int = 128;
	
	static public var tileSize(default, never):Int = 64;
	static public var attackMoveDist(default, never):Int = 16;
	
	
	public var name(default, null):String;
	
	public var level(default, null):String;
	public var exp:Int;
	
	public var maxHealth(default, null):Int;
	public var energy(default, null):Int;
	
	public var strength(default, null):Int;
	public var agility(default, null):Int;
	public var skill(default, null):Int;
	public var defense(default, null):Int;
	
	public var intel(default, null):Int;
	public var will(default, null):Int;
	public var presence(default, null):Int;
	
	public var luck(default, null):Int;
	
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
	
	// Temp derived statistics (for FE7-style combat)
	public var critChance(default, null):Int;
	public var dodge(default, null):Int;
	
	public var attackSpeed(default, null):Int;
	
	
	// Inventory
	
	public var inventory(default, null):Inventory;
	
	public var heldItemCount:Int = 0;
	public var itemsHaveChanged:Bool = false;
	
	// List of integer ranges this unit can attack from, based on contents of inventory.
	private var attackRanges:Array<Int>;
	
	// List of integer ranges this unit can heal, based on contents of inventory.
	private var healRanges:Array<Int>;
	
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
		teamP:TeamType, unitName:String) 
	{
		super(col * tileSize, row * tileSize);
		
		name = unitName;
		
		offset.x = 32;
		offset.y = 32;
		
		loadGraphic(spriteSheet, true, spriteWidth, spriteHeight);
		animation.add("up", [0, 1, 2, 3], 6);
		animation.add("down", [4, 5, 6, 7], 6);
		animation.add("right", [8, 11, 10, 9], 4);
		animation.add("left", [12, 13, 14, 15], 4);
		// Hover and idle haven't been drawn for the new sprite yet, so no animations for now.
		animation.add("hover", [16], 1);
		animation.add("idle", [16], 1);
		
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
		
		healRanges = [];
		attackRanges = [];
		
		inventory = new Inventory();
		inventory.owner = this;
		
		inventory.addItemToEnd(new WeaponItem("Javelin", [1, 2]));
		inventory.addItemToEnd(new WeaponItem("Longbow", [2]));
		inventory.addItemToEnd(new WeaponItem("Chakram", [1, 2]));
		inventory.addItemToEnd(new WeaponItem("Quarterstaff", [1]));
		
		(cast inventory.items[0]).weight = FlxG.random.int(1, 10);
		(cast inventory.items[1]).weight = FlxG.random.int(1, 10);
		(cast inventory.items[2]).weight = FlxG.random.int(1, 10);
		(cast inventory.items[3]).weight = FlxG.random.int(1, 10);
		
		inventory.finalizeItemInfo();
		
		equippedItem = cast inventory.items[0];
		
		maxHealth = FlxG.random.int(10, 30);
		health = maxHealth;
		energy = FlxG.random.int(5, 25);
		
		strength = FlxG.random.int(1, 10);
		agility = FlxG.random.int(1, 10);
		skill = FlxG.random.int(1, 10);
		defense = FlxG.random.int(1, 10);
		intel = FlxG.random.int(1, 10);
		luck = FlxG.random.int(1, 10);
		
		calcDerivedStats(equippedItem);
	}
	
	public function calcDerivedStats(itemToUse:EquippableItem):Void
	{
		attackSpeed = Math.floor(Math.max(agility - Math.max(itemToUse.weight - weight, 0), 0));
		accuracy = itemToUse.accuracy + skill * 2 + cast (luck / 2);
		evade = attackSpeed * 2 + luck;
		attackDamage = strength + itemToUse.weight;
		
		critChance = itemToUse.critChance + cast (skill / 2);
		dodge = luck;
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
	
	
	/**
	 * 
	 * @param	targetDirection
	 */
	private function beginMoving(targetDirection:Int):Void
	{
		
	}
	
	public function canEquipItem(item:Item):Bool
	{
		return true;
	}
	
	/**
	 * 
	 * @param	equipIndex
	 */
	public function equipItem(equipIndex:Int):Void
	{
		var tempItem:Item = inventory.items[0];
		
		inventory.items[equipIndex].insertIntoInv(inventory, 0);
		tempItem.insertIntoInv(inventory, equipIndex);
		
		// Cast the item to EquippedItem type.
		equippedItem = cast inventory.items[0];
	}
	
	/**
	 * 
	 * @param	target
	 */
	public function attackTarget(target:Unit):Void
	{
		
	}
	
	/**
	 * 
	 * @param	target
	 * @param	item
	 */
	public function useItem(target:Unit, item:Item):Void
	{
		item.use(this, target);
	}
	
	public function get_attackRanges():Array<Int>
	{
		if (itemsHaveChanged)
		{
			updateRanges();
			itemsHaveChanged = false;
		}
		
		return attackRanges;
	}
	
	public function get_healRanges():Array<Int>
	{
		if (itemsHaveChanged)
		{
			updateRanges();
			itemsHaveChanged = false;
		}
		
		return healRanges;
	}
	
	private function updateAttackRanges():Void
	{
		attackRanges.splice(0, attackRanges.length);
		
		for (weaponIndex in inventory.weaponIndices)
		{
			var weapon:WeaponItem = cast inventory.items[weaponIndex];
			
			for (range in weapon.ranges)
			{
				if (attackRanges.indexOf(range) == -1)
				{
					attackRanges.push(range);
				}
			}
		}
	}
	
	private function updateHealRanges():Void
	{
		
	}
	
	public function updateRanges():Void
	{
		updateAttackRanges();
		updateHealRanges();
	}
	
	static public function attackTweenFunc(unit:Unit, targetMoveID:MoveID, distTravelled:Float):Void
	{
		if (distTravelled > attackMoveDist)
		{
			distTravelled = attackMoveDist * 2 - distTravelled;
		}
		
		var unitLogicalCenter:FlxPoint = new FlxPoint();
		var targetLogicalCenter:FlxPoint = new FlxPoint();
		
		unitLogicalCenter.x = (unit.mapPos.getCol() + .5) * tileSize;
		unitLogicalCenter.y = (unit.mapPos.getRow() + .5) * tileSize;
		
		targetLogicalCenter.x = (targetMoveID.getCol() + .5) * tileSize;
		targetLogicalCenter.y = (targetMoveID.getRow() + .5) * tileSize;
		
		// Get the angle between two points in degrees. (straight up is 0 deg)
		var angle:Float = unitLogicalCenter.angleBetween(targetLogicalCenter) * Math.PI / 180; 
		
		unit.x = unit.mapPos.getCol() * tileSize + distTravelled * Math.sin(angle);
		unit.y = unit.mapPos.getRow() * tileSize + distTravelled * -Math.cos(angle);
	}
	
	public function attackAnimate(targetMoveID:MoveID):Void
	{
		FlxTween.num(0, Unit.attackMoveDist * 2, .3, {ease: FlxEase.quadInOut}, 
			Unit.attackTweenFunc.bind(this, targetMoveID));
	}
	
	override public function update(elapsed:Float):Void 
	{
		super.update(elapsed);
	}
	
	override public function hurt(Damage:Float):Void
	{
		super.hurt(Damage);
		health = Math.max(health, 0);
	}
	
	override public function kill():Void 
	{
		subject.notify(UnitEvents.DIED);
		super.kill();
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