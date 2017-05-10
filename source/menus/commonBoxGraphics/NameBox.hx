package menus.commonBoxGraphics;

import boxes.ResizableBox;
import boxes.VarSizedBox;
import flixel.group.FlxGroup;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
 * ...
 * @author Samuel Bumgardner
 */
class NameBox implements VarSizedBox
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
	
	
	public function new(?X:Float=0, ?Y:Float=0) 
	{
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
	
	public function setPos(newX:Float, newY:Float):Void
	{
		nameBox.setPos(newX, newY);
		nameText.setPosition(newX + cornerSize, newY + cornerSize);
	}
}