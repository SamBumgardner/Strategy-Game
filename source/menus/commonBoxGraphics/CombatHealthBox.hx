package menus.commonBoxGraphics;
import boxes.BoxCreator;
import boxes.VarSizedBox;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import units.Unit;
import utilities.LogicalContainer;

/**
 * ...
 * @author Samuel Bumgardner
 */
class CombatHealthBox implements VarSizedBox implements LogicalContainer
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
	
	
	/**
	 * x & y coordinates that all menu components should be positioned relative to.
	 * Can be changed by external entities using setPos().
	 */
	public var x(default, null):Float = 0;
	public var y(default, null):Float = 0;
	
	
	public function new(?X:Float = 0, ?Y:Float = 0) 
	{
		initName();
		initHealthComponents();
		initBox();
		
		addAllFlxGrps();
		
		setPos(X, Y);
	}
	
	
	private function initName():Void
	{
		nameText = new FlxText(cornerSize, cornerSize, boxWidth - cornerSize * 2, 
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
	
	/**
	 * Public function for changing the position of the menu and all of its components.
	 * 
	 * @param	newX	The menu's new x value.
	 * @param	newY	The menu's new y value.
	 */
	public function setPos(newX:Float, newY:Float):Void
	{
		var xDiff:Float = newX - x;
		var yDiff:Float = newY - y;
		
		// Move all HaxeFlixel-inheriting components.
		totalFlxGroup.forEach(moveObject.bind(_, xDiff, yDiff), true);
		
		// Update all nested logical x & y values.
		updateLogicalPos(xDiff, yDiff);
	}
	
	/**
	 * Helper function used by setPos().
	 * Is passed as the argument into an FlxGroup's forEach() to change the x values of all
	 * 	sprites in the menu's totalFlxGrp. 
	 * Because totalFlxGroup holds objects of type FlxBasic, the function has to test that the 
	 * 	"targetSprite" FlxBasic object is actually an FlxObject (or something that inherits 
	 * 	from it) so it has an x & y component to change.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 * @param	dX				The amount the targetObject's x should change by.
	 * @param	dY				The amount the targetObject's y should change by.
	 */
	private function moveObject(targetObject:FlxBasic, dX:Float, dY:Float):Void
	{
		if (Std.is(targetObject, FlxObject))
		{
			(cast targetObject).x += dX;
			(cast targetObject).y += dY;
		}
	}
	
	/**
	 * Function to satisfy LogicalContainerNester interface.
	 * Is used to update just this containers overall logical position without changing any
	 *  sprite positions. Needed when something composing this updates all sprite positions
	 *  itself, then needs to update container logical positions to match.
	 * 
	 * @param	diffX	The amount to change this container's logical X position by.
	 * @param	diffY	The amount to change this container's logical Y position by.
	 */
	public function updateLogicalPos(xDiff:Float, yDiff:Float):Void
	{
		x += xDiff;
		y += yDiff;
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