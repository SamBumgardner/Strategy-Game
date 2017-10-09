package menus.commonBoxGraphics;

import boxes.ResizableBox;
import boxes.VarSizedBox;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import utilities.LogicalContainer;
import utilities.LogicalContainerNester;

/**
 * ...
 * @author Samuel Bumgardner
 */
class NameBox implements VarSizedBox implements LogicalContainerNester
{
	public var maxWidth(default, never):Int = 300;
	
	/* INTERFACE boxes.VarSizedBox */
	
	public var boxWidth(default, null):Int;
	
	public var boxHeight(default, null):Int;
	
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_simple__png;
	
	public var cornerSize(default, null):Int = 10;
	
	public var backgroundSize(default, null):Int = 10;
	
	
	private var boxSpriteGrp:FlxGroup;
	
	
	private var textSize(default, never):Int = 16;
	
	public var nameText:FlxText;
	
	public var nameBox(default, null):ResizableBox;
	
	
	public var totalFlxGrp:FlxGroup;
	
	/**
	 * Array of logical containers that will need logical position updates when this object's
	 *  logical position updates.
	 */
	public var nestedContainers(null, null):Array<LogicalContainer> = new Array<LogicalContainer>();
	
	/**
	 * x & y coordinates that all visual components should be positioned relative to.
	 * Can be changed by external entities using setPos().
	 */
	public var x(default, null):Float;
	public var y(default, null):Float;
	
	
	public function new(?X:Float=0, ?Y:Float=0) 
	{
		x = X;
		y = Y;
		
		initName(X, Y);
		initBox(X, Y);
		
		setName("Placeholder");
		
		addAllFlxGrps();
	}
	
	private function initName(X:Float, Y:Float):Void
	{
		nameText = new FlxText(X + cornerSize, Y + cornerSize, 0, "Placeholder", textSize);
		nameText.color = FlxColor.BLACK;
		nameText.active = false;
	}
	
	/**
	 * Depends on nameText already being initialized. 
	 * 
	 * @param	X
	 * @param	Y
	 */
	private function initBox(X:Float, Y:Float):Void
	{
		boxSpriteGrp = new FlxGroup();
		
		boxWidth = maxWidth;
		boxHeight = Math.floor(nameText.height + cornerSize * 2);
		
		nameBox = new ResizableBox(X, Y, boxWidth, boxHeight, boxSpriteSheet,
			cornerSize, backgroundSize);
		
		boxSpriteGrp.add(nameBox.totalFlxGrp);
		nestedContainers.push(nameBox);
		
		nameBox.reveal();
	}
	
	private function addAllFlxGrps():Void
	{
		totalFlxGrp = new FlxGroup();
		
		totalFlxGrp.add(boxSpriteGrp);
		totalFlxGrp.add(nameText);
	}
	
	public function setName(newName:String):Void
	{
		nameText.text = newName;
		
		boxWidth = Math.floor(nameText.width + cornerSize * 2);
		
		nameBox.resize(boxWidth, boxHeight);
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
		totalFlxGrp.forEach(moveObject.bind(_, xDiff, yDiff), true);
		
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
		
		for (logicalContainer in nestedContainers) 
		{
			logicalContainer.updateLogicalPos(xDiff, yDiff);
		}
	}
}