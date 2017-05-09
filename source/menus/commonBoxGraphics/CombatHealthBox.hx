package menus.commonBoxGraphics;
import boxes.BoxCreator;
import boxes.VarSizedBox;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import units.Unit;

/**
 * ...
 * @author Samuel Bumgardner
 */
class CombatHealthBox implements VarSizedBox
{

	/* INTERFACE boxes.VarSizedBox */
	
	public var boxWidth(default, null):Int = 200;
	
	public var boxHeight(default, null):Int;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_simple__png;
	
	public var cornerSize(default, null):Int = 10;
	
	public var backgroundSize(default, null):Int = 10;
	
	
	private var textSize(default, never):Int = 16;
	
	public var nameText:FlxText;
	
	public var healthBar:FlxBar;
	
	public var healthCount:FlxText;
	
	public var healthCountValue:Float;
	
	public var boxSprite:FlxSprite;
	
	public var totalFlxGroup(default, null):FlxGroup = new FlxGroup();
	
	
	public var trackedUnit:Unit;
	
	
	public function new() 
	{
		initName(0, 0);
		initHealthComponents();
		initBox();
		addAllFlxGrps();
	}
	
	
	private function initName(X:Float, Y:Float):Void
	{
		nameText = new FlxText(X + cornerSize, Y + cornerSize, boxWidth - cornerSize * 2, 
			"Placeholder", textSize);
		nameText.color = FlxColor.BLACK;
		nameText.alignment = FlxTextAlign.CENTER;
		nameText.active = false;
	}
	
	private function initHealthComponents():Void
	{
		healthCount = new FlxText(nameText.x, nameText.y + 20, 32, "0", textSize);
		healthCount.alignment = FlxTextAlign.RIGHT;
		healthCount.color = FlxColor.BLACK;
		healthCount.active = false;
		
		healthBar = new FlxBar(healthCount.x + healthCount.width + 5, healthCount.y + 6, 
			null, Std.int(boxWidth - cornerSize * 2 - (healthCount.x + healthCount.width + 5)), 
			10, trackedUnit, "health", 0, 30, true);
	}
	
	private function initBox():Void
	{
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		
		boxHeight = Std.int(healthCount.y + healthCount.height + cornerSize);
		
		boxSprite = BoxCreator.createBox(boxWidth, boxHeight);
	}
	
	private function addAllFlxGrps():Void
	{
		totalFlxGroup.add(boxSprite);
		totalFlxGroup.add(nameText);
		totalFlxGroup.add(healthCount);
		totalFlxGroup.add(healthBar);
	}
	
	public function setUnit(newUnit:Unit):Void
	{
		if (newUnit != null)
		{
			trackedUnit = newUnit;
			
			nameText.text = newUnit.name;
			
			healthBar.setRange(0, trackedUnit.maxHealth);
			healthBar.setParent(trackedUnit, "health");
		}
	}
	
	public function setPos(X:Float, Y:Float):Void
	{
		boxSprite.setPosition(X, Y);
		nameText.setPosition(X + cornerSize, Y + cornerSize);
		
		healthCount.setPosition(nameText.x, nameText.y + 20);
		healthBar.setPosition(healthCount.x + healthCount.width + 5, healthCount.y + 2);
	}
	
	public function update(elapsed:Float):Void
	{
		if (trackedUnit != null && healthCountValue != trackedUnit.health)
		{
			healthCountValue = trackedUnit.health;
			healthCount.text = Std.string(healthCountValue);
		}
	}
}