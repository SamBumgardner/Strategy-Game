package menus;

import boxes.BoxCreator;
import boxes.VarSizedBox;
import cursors.AnchoredSprite;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import inputHandlers.ActionInputHandler.KeyIndex;
import observerPattern.eventSystem.EventTypes;
import observerPattern.Subject;
import utilities.UpdatingEntity;

/**
 * A basic menu class that uses an array of strings (provided as a parameter upon instantiation)
 * 	to create a basic vertical menu. 
 * 
 * @author Samuel Bumgardner
 */
class BasicMenu extends MenuTemplate implements VarSizedBox 
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Variables to satisfy VarSizedBox interface.
	 * Specifies the qualities of the menu's box.
	 */
	public var boxWidth(default, null):Int;
	public var boxHeight(default, null):Int;
	public var boxSpriteSheet(default, null):FlxGraphicAsset = AssetPaths.box_simple__png;
	public var cornerSize(default, null):Int		= 10;
	public var backgroundSize(default, null):Int	= 10;
	
	/**
	 * Variable for keeping track of the menu's background box FlxSprite.
	 */
	private var boxSpriteGrp:FlxGroup;

	/**
	 * Constant variables that define the font size of the labels and the vertical interval
	 * 	between them.
	 */
	private var labelTextSize(default, never):Int = 14;
	private var labelInterval(default, never):Float = 25;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	X				The desired x position of the menu.
	 * @param	Y				The desired y position of the menu.
	 * @param	labelTextArr	Array of strings for the menu's different options.
	 * @param	id				ID used by the menu's Subject component when notifying observers.
	 */
	public function new(X:Float, Y:Float, labelTextArr:Array<String>, ?id:Int = 0) 
	{
		super(X, Y, id);
		
		var maxTextWidth:Float = initMenuOptions(X, Y, labelTextArr);
		initBgGraphics(maxTextWidth);
		initVarSizedBox(X, Y, maxTextWidth);
		initBasicCursor();
		setScrollFactors();
		addAllFlxGrps();
		
		hide();
	}
	
	/**
	 * Uses the provided labelTextArr to create an array of MenuOption objects for the basic menu.
	 * Also responsible for finding the width of the largest MenuOption's label, which is needed
	 * 	by the menu's other initialization functions.
	 * 
	 * @param	labelTextArr	Array of strings, the label text for each of the menu options.
	 * @return	The width of the largest label, which is needed to create the background highlight graphics and variable-sized box.
	 */
	private function initMenuOptions(X:Float, Y:Float, labelTextArr:Array<String>):Float
	{
		var newMenuOption:MenuOption;
		var maxTextWidth:Float = 0;
		for (i in 0...labelTextArr.length)
		{
			// Create new menu option, do basic setup, and add to array of menu options.
			newMenuOption = new MenuOption(X + cornerSize, Y + cornerSize + labelInterval * i, 
				i, 0, labelTextArr[i], labelTextSize, true);
			newMenuOption.label.color = FlxColor.BLACK;
			menuOptionArr.push(newMenuOption);
			
			// Test if the current option's label is the widest so far.
			if (maxTextWidth < newMenuOption.label.width || i == 0)
			{
				maxTextWidth = newMenuOption.label.width;
			}
			
			// Connect the current menu option and the previous option as neighbors.
			if (i > 0) 
			{
				newMenuOption.upOption = menuOptionArr[i - 1];
				menuOptionArr[i - 1].downOption = newMenuOption;
			}
			
			// Connect the last menu option to the first menu option as neighbors.
			if (i == labelTextArr.length - 1)
			{
				menuOptionArr[0].upOption = menuOptionArr[i];
				menuOptionArr[0].upIsWrap = true;
				menuOptionArr[i].downOption = menuOptionArr[0];
				menuOptionArr[i].downIsWrap = true;
			}
			
			// Add the current menu option to the totalFlxGrp
			optionFlxGrp.add(newMenuOption.totalFlxGrp);
		}
		// Return the maximum label width.
		return maxTextWidth;
	}
	
	/**
	 * Creates background graphics for each of the MenuOptions using the provided maxTextWidth
	 * 	variable. 
	 * The backgrounds could not be created at the same time as the MenuOptions because
	 * 	the backgrounds should extend through the full length of the box, but the length of the 
	 * 	box is not known until the width of the largest MenuOption label is found.
	 * 
	 * @param	maxTextWidth	The width of the largest MenuOption's label.
	 */
	private function initBgGraphics(maxTextWidth:Float):Void
	{
		for (option in menuOptionArr)
		{
			option.addBgHighlightGraphic(maxTextWidth);
		}
	}
	
	/**
	 * Creates variable sized box sprite that sits behind the MenuOptions.
	 * Has to be created after the menu options so it knows how wide and tall it should be.
	 * 
	 * @param	maxTextWidth	The width of the largest MenuOption's label.
	 */
	private function initVarSizedBox(X:Float, Y:Float, maxTextWidth:Float):Void
	{
		var lastLabel:FlxText = menuOptionArr[menuOptionArr.length - 1].label;
		boxWidth = cast maxTextWidth + cornerSize * 2;
		boxHeight = cast lastLabel.y + lastLabel.height + cornerSize - Y;
		
		BoxCreator.setBoxType(boxSpriteSheet, cornerSize, backgroundSize);
		var boxSprite:FlxSprite = BoxCreator.createBox(boxWidth, boxHeight);
		boxSprite.x = X;
		boxSprite.y = Y;
		
		boxSpriteGrp = new FlxGroup();
		boxSpriteGrp.add(boxSprite);
	}
	
	/**
	 * Adds all of the menu's different FlxGrps to its totalFlxGrp in the correct order.
	 * The order matters because the first item added to totalFlxGrp will be drawn on the
	 * 	bottom layer, the next is drawn one layer above it, and so on.
	 * 
	 * For this menu, boxSpriteGrp is added first so it sits behind the group of menu options.
	 * 
	 * MenuTemplate's definition of this function is empty, so no call to super.addAllFlxGrps()
	 * 	is required.
	 */
	override private function addAllFlxGrps():Void
	{
		totalFlxGrp.add(boxSpriteGrp);
		totalFlxGrp.add(optionFlxGrp);
		totalFlxGrp.add(menuCursor);
	}
	
	
	///////////////////////////////////////
	//          CURSOR ACTIONS           //
	///////////////////////////////////////
	
	/**
	 * Recieves an array of boolean values that correspond to certain types of input, then
	 * 	determines what actions to take as a result of that input. This often involves
	 * 	notifying its observes that the event happened, and lets those observers take care
	 * 	of manipulation of external objects.
	 * 
	 * Is not expecting to ever get a call with heldAction being true (because it uses the 
	 * 	default MenuTemplate update function) but I set up the test at the start of the function 
	 * 	just in case.
	 * 
	 * @param	pressedKeys	Indicates which keys were pressed. Use KeyIndex enum (from ActionInputHandler) to identify what type of input each index corresponds to.
	 * @param	heldAction	Whether the provided set of pressed keys were held down for a length of time (true) or just pressed (false).
	 */
	private override function doCursorAction(pressedKeys:Array<Bool>, heldAction:Bool)
	{
		if (!heldAction)
		{
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
		}
	}
}