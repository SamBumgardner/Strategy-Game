package menus;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import utilities.HideableEntity;

/**
 * The basic building block of any menu-type object.
 * Has four major components:
 * 	- FlxPoint marking where the cursor should be anchored when pointing at this option.
 * 	
 * 	- References to MenuOptions that logically neighbor this option.
 * 		- Used when moving between menu options, can support menus of any shape and dimensions.
 * 			(functions like a linked graph/list scenario)
 * 		- Also has variables to track if a link between two options involves wrapping around to
 * 			the other side of the menu, which is useful for held cursor movement.
 * 
 * 	- FlxText label, can be left empty of text if no text is needed.
 * 
 * 	- FlxSprite bgHighlight, an optional component which becomes visible when the cursor points
 * 		at this particular option.
 * 
 * Menus of any configuration can create the options they need, position them properly, then
 * 	link the options to one another using the directional references.
 * 
 * See the BasicMenu class for a simple menu layout built using these components. 
 * 		
 * @author Samuel Bumgardner
 */
class MenuOption implements HideableEntity
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Point describing the x & y values that this MenuOption's label will be placed at.
	 */
	public var labelPos(default, null):FlxPoint = new FlxPoint();
	
	/**
	 * Length of the (square) cursor graphic used in the game. Change here if graphic size changes.
	 */
	private static var cursorSideLength(default, never):Int = 15;
	
	/**
	 * Adds to the cursorPos x & y components to calculate label x & y values. 
	 * Determined using cursorSideLength variable and the label height.
	 */
	public var cursorPos(default, null):FlxPoint = new FlxPoint();
	private var cursorOffsetX:Float = -1.5 * cursorSideLength;
	private var cursorOffsetY:Float;
	
	/**
	 * Text label for the menuOption. Could be left with no text if not desired.
	 * Is public so external classes can adjust color and formatting with less hassle.
	 */
	public var label:FlxText;
	
	/**
	 * Sprite positioned behind the label, only visible if this MenuOption is hovered over.
	 */
	public var bgHighlight:FlxSprite;
	private var isHovered:Bool = false;
	
	/**
	 * Collection of flixel components owned by this MenuOption.
	 */
	public var totalFlxGrp:FlxGroup = new FlxGroup();
	
	/**
	 * Number that can be used to identify this MenuOption.
	 */
	public var id:Int;
	
	/**
	 * Set of references that describes how this menuOption is positioned relative to
	 * 	other MenuOption objects in the same menu. Links MenuOptions to one another
	 * 	similarly to how a linked list/graph would work.
	 */
	public var upOption:MenuOption;
	public var downOption:MenuOption;
	public var leftOption:MenuOption;
	public var rightOption:MenuOption;
	
	/**
	 * Set of boolean variables that tell if an adjacent option is actually on the other side
	 * of the menu, so any cursor movement to that option will "wrap" around the menu.
	 * 
	 * This is good to know when moving the cursor between menuOptions, because most 
	 * (if not all) menus will stop the cursor at the end of a menu during held movement.
	 * To wrap the cursor around to the other side of the menu, a new input is required.
	 */
	public var upIsWrap:Bool = false;
	public var downIsWrap:Bool = false;
	public var leftIsWrap:Bool = false;
	public var rightIsWrap:Bool = false;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	labelX			X position for the label.
	 * @param	labelY			Y position for the label
	 * @param	ID				Integer ID that can be used to distinguish between MenuOptions
	 * @param	labelWidth		Width of the label text field.
	 * @param	labelText		String to be displayed in the label.
	 * @param	labelSize		Font size used in the label.
	 * @param	hasBgHighlight	Whether the default bgHighlight object should appear behind the menu option when hovered over.
	 */
	public function new(labelX:Float, labelY:Float, ?ID:Int = 0, ?labelWidth:Float = 0,
		?labelText:String = "", ?labelSize:Int = 8, ?hasBgHighlight:Bool = false) 
	{
		id = ID;
		
		label = new FlxText(labelX, labelY, labelWidth, labelText, labelSize);
		
		cursorOffsetY = (label.height / 2) - (cursorSideLength / 2);
		cursorPos.set(labelX + cursorOffsetX, labelY + cursorOffsetY);
		
		if (hasBgHighlight)
		{
			bgHighlight = new FlxSprite(label.x, label.y + label.height / 2);
			bgHighlight.active = false;
			bgHighlight.visible = false;
			totalFlxGrp.add(bgHighlight);
			
			if (labelWidth > 0)
			{
				addBgHighlightGraphic(labelWidth);
			}
		}
		
		totalFlxGrp.add(label);
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Moves the option's cursor position by the specified amount.
	 * 
	 * @param	xDiff	amount to change x by.
	 * @param	yDiff	amount to change y by.
	 */
	public function moveCursorPos(xDiff:Float, yDiff:Float):Void
	{
		cursorPos.x += xDiff;
		cursorPos.y += yDiff;
	}
	
	/**
	 * Generates a background highlight for the currentMenuOption of the specified width.
	 * Useful for MenuOptions that don't know how wide their field will be initially.
	 * Could be given expanded functionality in the future.
	 * 
	 * @param	width	The desired width of the new BgHighlight  graphic.
	 */
	public function addBgHighlightGraphic(width:Float):Void
	{
		if (bgHighlight.graphic != null)
		{
			trace("ERROR: created two graphics for one bgHighlight.");
		}
		
		bgHighlight.makeGraphic(cast width, cast label.height / 2, 0x55ffffff);
	}
	
	/**
	 * Function to call when the cursor moves to this MenuOption.
	 * May gain functionality in the future.
	 * 
	 * Needs to check if label is visible before making the background visible.
	 * If the label isn't visible, there's no reason that its background highlight should be.
	 */
	public function cursorEntered():Void
	{
		if (bgHighlight != null && label.visible)
		{
			bgHighlight.active = true;
			bgHighlight.visible = true;
		}
	}
	
	/**
	 * Function to call when the cursor leaves this MenuOption.
	 * May gain functionality in the future.
	 */
	public function cursorExited():Void
	{
		if (bgHighlight != null)
		{
			bgHighlight.active = false;
			bgHighlight.visible = false;
		}
	}
	
	/**
	 * Clips the bgHighlight graphic to the specified width.
	 *
	 * @param	newWidth	The desired width of the bgHighlight.
	 */
	public function clipBgHighlight(newWidth:Float):Void
	{
		bgHighlight.clipRect = new FlxRect(0, 0, newWidth, bgHighlight.height);
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menuOption's totalFlxGrp 
	 * 	invisible and inactive.
	 */
	public function hide():Void
	{
		totalFlxGrp.forEach(hideSprite, true);
	}
	
	/**
	 * Helper function used by hide().
	 * Takes an FlxBasic as a parameter, determines if it is an FlxSprite, and if it is
	 * 	it makes it invisible and inactive.
	 * It is necessary to check if the targetSprite is an FlxSprite because the FlxGroup
	 * 	it is used on is only guaranteed to have FlxBasic objects, which may or may not be
	 * 	sprites that need to be hidden.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 */
	private function hideSprite(targetSprite:FlxBasic):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).visible = false;
			(cast targetSprite).active = false;
		}
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menuOption's totalFlxGrp 
	 * 	invisible and inactive.
	 */
	public function reveal():Void
	{
		totalFlxGrp.forEach(revealSprite, true);
	}
	
	
	/**
	 * Helper function for reveal().
	 * Takes an FlxBasic as a parameter, determines if it is an FlxSprite, and if it is
	 * 	it makes it visible and active.
	 * It is necessary to check if the targetSprite is an FlxSprite because the FlxGroup
	 * 	it is used on is only guaranteed to have FlxBasic objects, which may or may not be
	 * 	sprites that need to be hidden.
	 * 
	 * @param	targetSprite	
	 */
	private function revealSprite(targetSprite:FlxBasic):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).visible = true;
			(cast targetSprite).active = true;
		}
	}
}