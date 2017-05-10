package menus.targetMenus;
import boxes.BoxCreator;
import boxes.VarSizedBox;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import inputHandlers.ActionInputHandler.KeyIndex;
import menus.MenuTemplate;
import menus.commonBoxGraphics.NameBox;
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
 * NOTE: Need to update documentation.
 * 
 * @author Samuel Bumgardner
 */
class AttackTargetMenu extends TargetMenuTemplate implements VarSizedBox
{
	public var selectedUnit:Unit;
	public var boxWidth(default, null):Int = 150;
	public var boxHeight(default, null):Int;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_simple__png;
	public var cornerSize(default, null):Int = 10;
	public var backgroundSize(default, null):Int = 10;
	
	public var totalWidth(default, null):Float;
	
	private var nameBox1:NameBox;
	private var nameBox2:NameBox;
	
	private var infoWindow:FlxSprite;
	
	private var textSize(default, never):Int = 15;
	
	private var weaponName1:FlxText;
	private var weaponName2:FlxText;
	private var InfoArray:Array<Array<FlxText>>;
	
	private var infoArrGrp:FlxGroup;
	
	private var validWeaponIndices:Array<Int> = new Array<Int>();
	private var currWeaponIndexID:Int = 0;
	private var currWeaponIndex(default, set):Int = 0;

	private var nameBox2OffsetX:Float;
	private var nameBox2OffsetY:Float;
	
	private var playerTextColor:FlxColor = 0x2a45a8;
	private var enemyTextColor:FlxColor = 0x721414;
	
	
	/**
	 * Initializer
	 */
	public function new(?ID:Int = 0)
	{
		super(ID);
		
		nameBox1 = new NameBox(x, y);
		nameBox1.nameText.color = playerTextColor;
		
		var infoArrayOffsetX = 20;
		var infoArrayOffsetY = nameBox1.boxHeight - 10;
		
		initInfoArray(infoArrayOffsetX, infoArrayOffsetY);
		initInfoWindow(infoArrayOffsetX, infoArrayOffsetY);
		
		nameBox2OffsetY = infoWindow.y + infoWindow.height;
		nameBox2 = new NameBox(x, y + nameBox2OffsetY);
		nameBox2.nameText.color = enemyTextColor;
		
		// Shift nameBox2 over to the right.
		nameBox2OffsetX = infoWindow.x + boxWidth + infoArrayOffsetX - nameBox2.boxWidth;
		
		nameBox2.setPos(x + nameBox2OffsetX, y + nameBox2OffsetY); 
		totalWidth = nameBox2.nameBox.x + nameBox2.boxWidth - nameBox1.nameBox.x;
		
		addAllFlxGrps();
		
		hide();
	}
	
	private function initInfoArray(X:Float, Y:Float):Void
	{
		infoArrGrp = new FlxGroup();
		
		var wName1OffsetY = 15;
		
		weaponName1 = new FlxText(X + cornerSize, Y + wName1OffsetY, boxWidth - cornerSize * 2, 
			"Placeholder", textSize);
		weaponName1.color = playerTextColor;
		weaponName1.active = false;
		
		infoArrGrp.add(weaponName1);
		
		InfoArray = new Array<Array<FlxText>>();
		
		var infoArrayOffsetY = 45;
		
		var infoArrayIntervalX = 50;
		var infoArrayIntervalY = 30;
		
		var infoTextWidth = 50;
		
		for (row in 0...InfoWindowRows.NUM_ROWS)
		{
			InfoArray.push(new Array<FlxText>());
			for (col in 0...InfoWindowCols.NUM_COLS)
			{
				var infoEntry:FlxText = new FlxText(X + infoArrayIntervalX * col, 
					Y + infoArrayOffsetY + infoArrayIntervalY * row, infoTextWidth, 
					"", textSize);
				
				// Set text color
				if (col == InfoWindowCols.PLAYER_INFO)
				{
					infoEntry.color = playerTextColor;
				}
				else if (col == InfoWindowCols.ENEMY_INFO)
				{
					infoEntry.color = enemyTextColor;
				}
				else
				{
					infoEntry.color = (FlxColor.BLACK);
				}
				
				infoEntry.alignment = FlxTextAlign.CENTER;
				infoEntry.active = false;
				
				infoArrGrp.add(infoEntry);
				
				InfoArray[row].push(infoEntry);
			}
		}
		
		InfoArray[InfoWindowRows.HEALTH][InfoWindowCols.LABEL].text = "HP";
		InfoArray[InfoWindowRows.MIGHT][InfoWindowCols.LABEL].text = "Mt";
		InfoArray[InfoWindowRows.HIT][InfoWindowCols.LABEL].text = "Hit";
		InfoArray[InfoWindowRows.CRIT][InfoWindowCols.LABEL].text = "Crit";
		
		var bottomOfInfoArray = InfoArray[InfoWindowRows.CRIT][InfoWindowCols.LABEL].y +
			InfoArray[InfoWindowRows.CRIT][InfoWindowCols.LABEL].height;
		
		var weaponName2offsetY = bottomOfInfoArray + (infoArrayOffsetY - (weaponName1.y + 
			weaponName1.height));
		
		weaponName2 = new FlxText(X + cornerSize, Y + weaponName2offsetY, 
			boxWidth - cornerSize * 2, "Placeholder", textSize);
		
		weaponName2.alignment = FlxTextAlign.RIGHT;
		weaponName2.color = enemyTextColor;
		weaponName2.active = false;
		
		infoArrGrp.add(weaponName2);
	}
	
	/**
	 * Should only be called after initInfoArray();
	 */
	private function initInfoWindow(X:Float, Y:Float):Void
	{
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		
		var bufferSpaceAtEnd = 15;
		
		boxHeight = Math.floor(weaponName2.y + weaponName2.height + bufferSpaceAtEnd - Y);
		
		infoWindow = BoxCreator.createBox(boxWidth, boxHeight);
		infoWindow.setPosition(X, Y);
	}
	
	/**
	 * 
	 */
	override private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(infoWindow);
		totalFlxGrp.add(infoArrGrp);
		totalFlxGrp.add(nameBox1.totalFlxGrp);
		totalFlxGrp.add(nameBox2.totalFlxGrp);
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
		
		nameBox1.setName(selectedUnit.name);
		
		// Get array of valid units, then cast to store as Array<OnMapEntity>
		possibleTargets = cast parentState.getValidUnitsInRange(
			selectedUnit.get_attackRanges(), SimpleTargetTests.enemyUnitTest);
		
		// Set up the equipped weapon as the default item upon equip
		if (selectedUnit.equippedItem != null && 
			selectedUnit.equippedItem.itemType == ItemTypes.WEAPON)
		{
			currWeaponIndex = selectedUnit.inventory.items.indexOf(selectedUnit.equippedItem);
		}
		
		// Assumes that there is at least one entry in possibleTargets. 
		// If there wasn't then this menu shouldn't be reachable in the first place.
		currentTarget = possibleTargets[0];
	}
	
	/**
	 * 
	 * @return
	 */
	private function findValidWeaponIndices():Void
	{
		// Clear current validWeaponIndices array.
		validWeaponIndices.splice(0, validWeaponIndices.length);
		
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
		
		weaponName1.text = selectedUnit.inventory.items[newWeaponIndex].name;
		
		if (selectedUnit != null && currentTarget != null)
		{
			setInfoArrayColumn(InfoWindowCols.PLAYER_INFO, selectedUnit, cast currentTarget);
			setInfoArrayColumn(InfoWindowCols.ENEMY_INFO, cast currentTarget, selectedUnit);
		}
		
		return currWeaponIndex = newWeaponIndex;
	}
	
	private override function set_currentTarget(newTarget:OnMapEntity):OnMapEntity
	{
		currentTarget = newTarget;
		
		findValidWeaponIndices();
		
		var otherUnit:Unit = cast newTarget;
		
		setInfoArrayColumn(InfoWindowCols.PLAYER_INFO, selectedUnit, otherUnit);
		setInfoArrayColumn(InfoWindowCols.ENEMY_INFO, otherUnit, selectedUnit);
		
		// Need to handle case where other unit has no weapon equipped.
		weaponName2.text = otherUnit.equippedItem.name;
		
		nameBox2.setName(otherUnit.name);
		
		nameBox2OffsetX = infoWindow.x + boxWidth + 20 - nameBox2.boxWidth;
		
		nameBox2.setPos(nameBox2OffsetX, nameBox2OffsetY); 
		totalWidth = nameBox2.nameBox.x + nameBox2.boxWidth - nameBox1.nameBox.x;
		
		
		return currentTarget;
	}
	
	private function setInfoArrayColumn(colIndex:Int, new_unit:Unit, enemy_unit:Unit):Void
	{	
		InfoArray[InfoWindowRows.HEALTH][colIndex].text = Std.string(new_unit.health);
		
		InfoArray[InfoWindowRows.MIGHT][colIndex].text = 
			Std.string(Std.int(Math.max(new_unit.attackDamage - enemy_unit.defense, 0)));
		
		InfoArray[InfoWindowRows.HIT][colIndex].text = 
			Std.string(Std.int(Math.min(Math.max(new_unit.accuracy - enemy_unit.evade, 0), 100)));
		
		InfoArray[InfoWindowRows.CRIT][colIndex].text = 
			Std.string(Std.int(Math.min(Math.max(new_unit.critChance - enemy_unit.dodge, 0), 100)));
	}
	
	public override function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool)
	{
		if (!heldAction)
		{
			// Could also be done with a loop, but this ends up being easier to understand.
			if (pressedKeys[KeyIndex.CONFIRM])
			{
				confirmSound.play(true);
				
				selectedUnit.equipItem(currWeaponIndex);
				
				subject.notify(EventTypes.CONFIRM);
			}
			else if (pressedKeys[KeyIndex.CANCEL])
			{
				cancelSound.play(true);
				subject.notify(EventTypes.CANCEL);
			}
			else if (pressedKeys[KeyIndex.NEXT])
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
			else if (pressedKeys[KeyIndex.INFO])
			{
				if (validWeaponIndices.length > 1)
				{
					// Cycle backward through weapons
					currWeaponIndexID = (currWeaponIndexID + 1) % validWeaponIndices.length;
					currWeaponIndex = validWeaponIndices[currWeaponIndexID];
				}
			}
		}
	}
	
	override public function setPos(newX:Float, newY:Float):Void
	{
		super.setPos(newX, newY);
		
		nameBox1.nameBox.x = newX;
		nameBox1.nameBox.y = newY;
		
		nameBox2.nameBox.x = newX + nameBox2OffsetX;
		nameBox2.nameBox.y = newY + nameBox2OffsetY;
	}
}

@:enum
class InfoWindowRows
{
	public static var HEALTH(default, never)        = 0;
	public static var MIGHT(default, never)         = 1;
	public static var HIT(default, never)           = 2;
	public static var CRIT(default, never)          = 3;
	
	public static var NUM_ROWS(default, never) = 4;
}

@:enum
class InfoWindowCols
{
	public static var PLAYER_INFO(default, never) = 0;
	public static var LABEL(default, never)       = 1;
	public static var ENEMY_INFO(default, never)  = 2;
	
	public static var NUM_COLS(default, never) = 3;
}