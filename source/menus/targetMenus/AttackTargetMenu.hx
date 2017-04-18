package menus.targetMenus;
import boxes.BoxCreator;
import boxes.VarSizedBox;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import inputHandlers.ActionInputHandler.KeyIndex;
import menus.MenuTemplate;
import missions.MissionState;
import observerPattern.eventSystem.EventTypes;
import units.Unit;
import units.items.ItemTypes;
import units.targeting.SimpleTargetTests;
import utilities.OnMapEntity;

using units.movement.MoveIDExtender;

/**
 * A target-style menu used to select which enemy to attack.
 * 
 * @author Samuel Bumgardner
 */
class AttackTargetMenu extends TargetMenuTemplate implements VarSizedBox
{
	public var selectedUnit:Unit;
	public var boxWidth(default, null):Int = 150;
	public var boxHeight(default, null):Int = 300;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_simple__png;
	public var cornerSize(default, null):Int = 10;
	public var backgroundSize(default, null):Int = 10;
	
	private var infoWindow:FlxSprite;
	
	private var InfoArray:Array<Array<FlxText>>;
	
	private var validWeaponIndices:Array<Int> = new Array<Int>();
	private var currWeaponIndexID:Int = 0;
	private var currWeaponIndex(default, set):Int = 0;
	
	/**
	 * Initializer
	 */
	public function new(?ID:Int = 0)
	{
		super(ID);
		
		initInfoWindow();
		initInfoArray();
		
	}
	
	private function initInfoWindow():Void
	{
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		infoWindow = BoxCreator.createBox(boxWidth, boxHeight);
		infoWindow.visible = false;
		totalFlxGrp.add(infoWindow);
	}
	
	private function initInfoArray():Void
	{
		InfoArray = new Array<Array<FlxText>>();
		
		for (row in 0...InfoWindowRows.NUM_ROWS)
		{
			InfoArray.push(new Array<FlxText>());
			for (col in 0...InfoWindowCols.NUM_COLS)
			{
				var infoEntry:FlxText = new FlxText(x + 50 * col, 
					y + 10 + 30 * (row + 1), 50, "", 15);
				infoEntry.color = (FlxColor.BLACK);
				infoEntry.alignment = FlxTextAlign.CENTER;
				infoEntry.visible = false;
				infoEntry.active = false;
				
				totalFlxGrp.add(infoEntry);
				
				InfoArray[row].push(infoEntry);
			}
		}
		
		InfoArray[InfoWindowRows.HEALTH][InfoWindowCols.LABEL].text = "HP";
		InfoArray[InfoWindowRows.ENERGY][InfoWindowCols.LABEL].text = "EN";
		InfoArray[InfoWindowRows.EVADE_COST][InfoWindowCols.LABEL].text = "E/C";
		InfoArray[InfoWindowRows.ATTACK_COST][InfoWindowCols.LABEL].text = "A/C";
		InfoArray[InfoWindowRows.ATTACK_DAMAGE][InfoWindowCols.LABEL].text = "A/D";
		InfoArray[InfoWindowRows.CRIT_COST][InfoWindowCols.LABEL].text = "C/C";
		InfoArray[InfoWindowRows.CRIT_DAMAGE][InfoWindowCols.LABEL].text = "C/D";
		
	}
	
	/**
	 * Identifies all valid targets within this unit's equipped item's range, then
	 * 	stores those units as an array of OnMapEntity objects in its possibleTargets array.
	 * 
	 * Assumes that the selected unit has a WeaponItem-type item equipped. 
	 * If not, unsafe casting will result in a crash.
	 * 
	 * @param	parentState
	 */
	public override function refreshTargets(parentState:MissionState):Void
	{
		selectedUnit = parentState.getSelectedUnit();
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange(
			selectedUnit.attackRanges, SimpleTargetTests.enemyUnitTest);
		
		// Assumes that there is at least one entry in possibleTargets. 
		// If there wasn't then this menu shouldn't be reachable in the first place.
		setInfoArrayColumn(InfoWindowCols.PLAYER_INFO, selectedUnit, cast possibleTargets[0]);
	}
	
	/**
	 * 
	 * @return
	 */
	private function findValidWeaponIndices():Void
	{
		// Clear current validWeaponIndices array.
		validWeaponIndices.splice(0, -1);
		
		var changeWeapon:Bool = true;
		
		var distToTarget:Int = selectedUnit.mapPos.getDistFromOther(currentTarget.mapPos);
		for (i in selectedUnit.inventory.weaponIndices)
		{
			// Check if the target is in this weapon's range.
			if (selectedUnit.inventory.items[i].ranges.indexOf(distToTarget) != -1)
			{
				// If so, add its index to the list of valid WeaponIndices.
				validWeaponIndices.push(i);
				
				if (i == currWeaponIndex)
				{
					changeWeapon = false;
					currWeaponIndexID = validWeaponIndices.length - 1;
				}
			}
		}
		
		if (changeWeapon)
		{
			currWeaponIndexID = 0;
			currWeaponIndex = validWeaponIndices[currWeaponIndexID];
		}
	}
	
	private function set_currWeaponIndex(newWeaponIndex:Int):Int
	{
		selectedUnit.calcDerivedStats(cast selectedUnit.inventory.items[newWeaponIndex]);
		return currWeaponIndex = newWeaponIndex;
	}
	
	private override function set_currentTarget(newTarget:OnMapEntity):OnMapEntity
	{
		currentTarget = newTarget;
		
		findValidWeaponIndices();
		
		var otherUnit:Unit = cast newTarget;
		
		setInfoArrayColumn(InfoWindowCols.PLAYER_INFO, selectedUnit, otherUnit);
		setInfoArrayColumn(InfoWindowCols.ENEMY_INFO, otherUnit, selectedUnit);
		
		return currentTarget;
	}
	
	private function setInfoArrayColumn(colIndex:Int, new_unit:Unit, enemy_unit:Unit):Void
	{
		InfoArray[InfoWindowRows.HEALTH][colIndex].text = Std.string(new_unit.health);
		InfoArray[InfoWindowRows.ENERGY][colIndex].text = Std.string(new_unit.energy);
		
		InfoArray[InfoWindowRows.EVADE_COST][colIndex].text = 
			Std.string(Std.int(Math.max(enemy_unit.accuracy - new_unit.evade, 1)));
		
		InfoArray[InfoWindowRows.ATTACK_COST][colIndex].text = 
			Std.string(new_unit.attackCost);
		InfoArray[InfoWindowRows.ATTACK_DAMAGE][colIndex].text = 
			Std.string(Std.int(Math.max(new_unit.attackDamage - enemy_unit.defense, 0)));
		
		InfoArray[InfoWindowRows.CRIT_COST][colIndex].text = 
			Std.string(new_unit.critCost + enemy_unit.intel);
		InfoArray[InfoWindowRows.CRIT_DAMAGE][colIndex].text = 
			Std.string(Std.int(Math.max(new_unit.critDamage - enemy_unit.defense, 0)));
	}
	
	public override function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool)
	{
		// Could also be done with a loop, but this ends up being easier to understand.
		if (pressedKeys[KeyIndex.CONFIRM])
		{
			confirmSound.play(true);
			subject.notify(EventTypes.CONFIRM);
		}
		else if (pressedKeys[KeyIndex.CANCEL])
		{
			cancelSound.play(true);
			subject.notify(EventTypes.CANCEL);
		}
		else if (pressedKeys[KeyIndex.INFO])
		{
			subject.notify(EventTypes.INFO);
		}
		else if (pressedKeys[KeyIndex.NEXT])
		{
			if (validWeaponIndices.length > 1)
			{
				// Cycle backward through weapons
				currWeaponIndexID = currWeaponIndexID + 1 % validWeaponIndices.length;
				currWeaponIndex = validWeaponIndices[currWeaponIndexID];
			}
		}
		else if (pressedKeys[KeyIndex.PAINT])
		{
			if (validWeaponIndices.length > 1)
			{
				// Cycle forward through weapons
				if (currWeaponIndexID != 0)
				{
					currWeaponIndexID = currWeaponIndexID - 1;
				}
				else
				{
					currWeaponIndexID = validWeaponIndices.length - 1;
				}
				currWeaponIndex = validWeaponIndices[currWeaponIndexID];
			}
		}
	}
}

@:enum
class InfoWindowRows
{
	public static var HEALTH(default, never)        = 0;
	public static var ENERGY(default, never)        = 1;
	public static var EVADE_COST(default, never)    = 2;
	public static var ATTACK_COST(default, never)   = 3;
	public static var ATTACK_DAMAGE(default, never) = 4;
	public static var CRIT_COST(default, never)     = 5;
	public static var CRIT_DAMAGE(default, never)   = 6;
	
	public static var NUM_ROWS(default, never) = 7;
}

@:enum
class InfoWindowCols
{
	public static var PLAYER_INFO(default, never) = 0;
	public static var LABEL(default, never)       = 1;
	public static var ENEMY_INFO(default, never)  = 2;
	
	public static var NUM_COLS(default, never) = 3;
}