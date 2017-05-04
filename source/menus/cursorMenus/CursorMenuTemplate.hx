package menus.cursorMenus;

import cursors.AnchoredSprite;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import inputHandlers.ActionInputHandler;
import inputHandlers.MoveInputHandler;
import menus.cursorMenus.MenuOption;
import observerPattern.eventSystem.EventTypes;
import utilities.HideableEntity;
import observerPattern.Observed;
import observerPattern.Subject;
import utilities.UpdatingEntity;

/**
 * Base class for all other cursor-based menu classes to inherit from.
 * 
 * Lays out the base logic for important menu functions, including:
 * 	- Containing MenuOptions.
 * 	- Cursor creation.
 * 		- Includes side-to-side bouncing motion and moving between menu options.
 * 	- Cursor movement.
 * 		- Includes tracking the current menu option for movement and action input purposes.
 * 
 * Check out the MenuOption class to see the basic unit that menus are built from.
 * Check out the BasicMenu class for an example of a child menu class that uses the 
 * 	functionality put together in here to make a working game menu.
 * 
 * @author Samuel Bumgardner
 */
class CursorMenuTemplate extends MenuTemplate
{	
	/**
	 * FlxGroup that only holds the HaxeFlixel components from this menu's MenuOptions.
	 */
	private var optionFlxGrp:FlxGroup = new FlxGroup();
	
	/**
	 * Array of menuOption objects. At the moment, this is just used to find the
	 *  first menu option whenever the menu is re-opened (so the cursor always starts
	 *  at the same position every time). 
	 * 
	 * If it ends up not being used for anything else in this template, then it will
	 *  be removed from here and added to any child classes that specifically need this
	 *  functionality.
	 */
	private var menuOptionArr:Array<MenuOption> = new Array<MenuOption>();
	
	/**
	 * The menu option that the cursor is currently selecting/hovering over.
	 */
	public var currMenuOption(default, null):MenuOption;
	
	/**
	 * The AnchoredSprite used as the menu's bouncing cursor.
	 */
	private var menuCursor:AnchoredSprite;
	
	/**
	 * Variables used to set up and manage the menuCursor's tweening. 
	 * The NumTween is what makes the menuCursor bounce left and right
	 * 	while it's visible.
	 */
	private var menuCursorTween:NumTween;
	private var bounceDistance(default, never):Int = 15;
	
	/**
	 * Constant value that indicates how many frames the menuCursor should take to
	 * 	complete any movement. When the cursor begins movement, its framesLeftinMove
	 * 	variable should be set equal to this.
	 */
	private var framesPerMove(default, never):Int = 4;
	
	/**
	 * Frame counter that tracks how many frames that the menuCursor has left during
	 * 	its current movement. When it is equal to 0, the menuCursor should be at its
	 * 	destination.
	 */
	private var framesLeftInMove:Int = 0;
	
	/**
	 * Initializer.
	 * 
	 * @param	X			x-coordinate for the new menu.
	 * @param	Y			y-coordinate for the new menu.
	 * @param	subjectID	ID for this menu's Subject, used when events are notified. 
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?subjectID:Int = 0)
	{
		super(X, Y, subjectID);
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Public function for changing the position of the menu and all of its components.
	 * Extends normal MenuTemplate behavior to also update menuOption cursor positions.
	 * 
	 * @param	newX	The menu's new x value.
	 * @param	newY	The menu's new y value.
	 */
	override public function setPos(newX:Float, newY:Float):Void
	{
		var xDiff:Float = newX - x;
		var yDiff:Float = newY - y;
		
		// Move cursor positions for all MenuOptions.
		for (menuOption in menuOptionArr)
		{
			menuOption.moveCursorPos(xDiff, yDiff);
		}
		
		super.setPos(newX, newY);
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
	 * Extends normal MenuTemplate behavior to also disable the menuCursor's bouncing animation.
	 */
	override public function hide():Void
	{
		super.hide();
		menuCursorTween.active = false;
	}
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
	 * Also is responsible for calling reset menu to give the menu its initial appearance again.
	 * Extends normal MenuTemplate behavior to re-activate the menuCursor's bouncing animation.
	 */
	override public function reveal():Void
	{
		super.reveal();
		menuCursorTween.active = true;
	}
	
	/**
	 * Defines the default "cursor menu" resetMenuBehavior.
	 * Is responsible for resetting the menu's variables and appearance back to their
	 * 	starting states. This includes hiding the background highlight graphic of all menu
	 * 	options that are not initially hovered over in the menu.
	 * 
	 * NOTE: Assumes that there is at least one entry in menuOptionArr.
	 */
	override private function resetMenu():Void
	{
		currMenuOption = menuOptionArr[0];
		menuCursor.setAnchor(currMenuOption.cursorPos.x, currMenuOption.cursorPos.y);
		menuCursor.jumpToAnchor();
		
		for (menuOption in menuOptionArr)
		{
			if (menuOption != currMenuOption && menuOption.bgHighlight != null)
			{
				hideSprite(menuOption.bgHighlight);
			}
		}
	}
	
	///////////////////////////////////////
	//        BASIC CURSOR SETUP         //
	///////////////////////////////////////
	
	/**
	 * Creates the cursor anchor sprite and sets up a tween for it using cursorBounceFunc().
	 * NOTE: menuCursor must still be added to totalFlxGrp after this function is finished!
	 * 
	 * Should be called during the initialization of child classes to set up the cursor.
	 */
	private function initBasicCursor():Void
	{
		menuCursor = new AnchoredSprite(0, 0, AssetPaths.menu_cursor_simple__png);
		menuCursorTween = FlxTween.num(0, bounceDistance, .75, {ease: FlxEase.circInOut, 
			type: FlxTween.LOOPING}, cursorBounceFunc.bind(menuCursor));
	}
	
	/**
	 * Tween function for use in a NumTween created in initBasicCursor().
	 * 
	 * Because HaxeFlixel doesn't allow looping chained tweens, I had to do a bit of a hacky
	 *  function here to make the whole movement in a single tween. Basically, when the bounce
	 *  is half over (offsetValue > corner.width /2) offsetValue is changed so it counts back to
	 *  zero, making the first half move the cursor to the right, and the second half expand it
	 *  again.
	 * 
	 * @param	cursor		The cursor object that is being tweened.
	 * @param	offsetValue	How far the cursor should be offset from its anchor.
	 */
	private function cursorBounceFunc(cursor:AnchoredSprite, offsetValue:Float):Void
	{
		if (offsetValue > bounceDistance / 2)
		{
			offsetValue = bounceDistance - offsetValue;
		}
		
		var offsetX:Float = offsetValue;
		
		cursor.x = cursor.getAnchorX() + offsetX;
		cursor.y = cursor.getAnchorY();
	}
	
	
	///////////////////////////////////////
	//          CURSOR MOVEMENT          //
	///////////////////////////////////////
	
	/**
	 * Recieves a set of boolean input values and moves the cursor to the appropriate
	 * 	menuOption in response.
	 * 
	 * The logic used here should be (for the most part) be used by all cursor-type menus.
	 * 	It identifies the direction of movement, changes currMenuOption to reference the
	 * 	MenuOption in that direction and changes the cursor's anchor values to match that new 
	 * 	currMenuOption. 
	 * 
	 * NOTE: Held movement input cannot be used to move to a "wrapping" adjacent neighbor. This
	 * 	depends on the MenuOptions indicating that a particular neighbor is adjacent via wrapping,
	 * 	though, so this behavior can be prevented if the MenuOptions are set up improperly.
	 * 
	 * @param	vertMove	indicates presence and direction of vertical movement input.
	 * @param	horizMove	indicates presence and direction of horizontal movement input.
	 * @param	heldMove	indicates whether the movement input was "held" or pressed this frame.
	 */
	override private function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void
	{
		if (!heldMove || framesLeftInMove == 0)
		{
			currMenuOption.cursorExited();
			
			if (vertMove > 0)
			{
				if (currMenuOption.downOption != null && 
					(!heldMove || !currMenuOption.downIsWrap))
				{
					currMenuOption = currMenuOption.downOption;
					moveSound.play(true);
				}
			}
			else if (vertMove < 0)
			{
				if (currMenuOption.upOption != null && 
					(!heldMove || !currMenuOption.upIsWrap))
				{
					currMenuOption = currMenuOption.upOption;
					moveSound.play(true);
				}
			}
			
			if (horizMove > 0)
			{
				if (currMenuOption.rightOption != null && 
					(!heldMove || !currMenuOption.rightIsWrap))
				{
					currMenuOption = currMenuOption.rightOption;
					moveSound.play(true);
				}
			}
			else if (horizMove < 0)
			{
				if (currMenuOption.leftOption != null && 
					(!heldMove || !currMenuOption.leftIsWrap))
				{
					currMenuOption = currMenuOption.leftOption;
					moveSound.play(true);
				}
			}
			currMenuOption.cursorEntered();
			framesLeftInMove = framesPerMove;
		}
	}
	
	
	/**
	 * Moves the cursor's corners toward the cursor's position incrementally.
	 */
	private function moveCursorAnchors():Void
	{
		if (framesLeftInMove > 0)
		{
			var horizMove:Int	= 0;
			var vertMove:Int	= 0;
			
			var xDiff:Int = Math.floor(currMenuOption.cursorPos.x) - 
				Math.floor(menuCursor.getAnchorX());
			var yDiff:Int = Math.floor(currMenuOption.cursorPos.y) - 
				Math.floor(menuCursor.getAnchorY());
			
			horizMove = cast xDiff / framesLeftInMove;
			vertMove = cast yDiff / framesLeftInMove;
			
			menuCursor.setAnchor(menuCursor.getAnchorX() + horizMove,
				menuCursor.getAnchorY() + vertMove);
			framesLeftInMove--;
		}
	}
	
	
	///////////////////////////////////////
	//          CURSOR ACTIONS           //
	///////////////////////////////////////
	
	/**
	 * Recieves an array of boolean values that correspond to certain types of input, then
	 * 	determines what actions to take as a result of that input. This often involves
	 * 	notifying its observers that the event happened, and then lets
	 * 	those observers take care of manipulation of external objects.
	 * 
	 * Can (and probably should) be overridden by child classes of this, since different
	 * 	menus may not need to notify PAINT, NEXT, or INFO events. If it is overridden with
	 * 	the intent to replace this function, make sure to NOT call super.doCursorAction();
	 * 
	 * @param	pressedKeys	Indicates which keys were pressed. Use KeyIndex enum (from ActionInputHandler) to identify what type of input each index corresponds to.
	 * @param	heldAction	Whether the provided set of pressed keys were held down for a length of time (true) or just pressed (false).
	 */
	override private function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool):Void
	{
		if (!heldAction)
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
			else if (pressedKeys[KeyIndex.PAINT])
			{
				subject.notify(EventTypes.PAINT);
			}
			else if (pressedKeys[KeyIndex.NEXT])
			{
				subject.notify(EventTypes.NEXT);
			}
			else if (pressedKeys[KeyIndex.INFO])
			{
				subject.notify(EventTypes.INFO);
			}
		}
	}
	
	
	///////////////////////////////////////
	//         UPDATE FUNCTIONS          //
	///////////////////////////////////////
	
	/**
	 * Update function.
	 * 
	 * NOTE: Movement handling comes before action handling because particular actions
	 * 	may cause the menu to no longer be active/visible. Movements, on the other hand,
	 * 	cannot change the active/visible qualities of the menu.
	 * 
	 * 	Because of this, I decided to resolve movement first, then cursor actions. 
	 * 
	 * @param	elapsed	Time passed since last call to update (in seconds).
	 */
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		
		if (active)
		{
			moveCursorAnchors();
		}
	}
}