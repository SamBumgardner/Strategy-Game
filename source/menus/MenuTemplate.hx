package menus;

import cursors.AnchoredSprite;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.tweens.misc.NumTween;
import inputHandlers.ActionInputHandler;
import inputHandlers.MoveInputHandler;
import observerPattern.eventSystem.EventTypes;
import utilities.HideableEntity;
import observerPattern.Observed;
import observerPattern.Subject;
import utilities.UpdatingEntity;

/**
 * Base class for all other menu classes to inherit from.
 * 
 * Lays out the base logic for important menu functions, including:
 * 	- Containing MenuOptions.
 * 	- Hiding menu and all components.
 * 	- Activating/Deactivating menu.
 * 	- Reacting to user "action" input.
 * 		- Uses observer pattern-style system, using its Subject component to notify observers.
 * 	- Cursor creation.
 * 		- Includes side-to-side bouncing motion and moving between menu options.
 * 	- Cursor movement.
 * 		- Includes tracking the current menu option for movement and action input purposes.
 * 	- Menu movement.
 * 		- Includes moving all menu components to match.
 * 
 * Check out the MenuOption class to see the basic unit that menus are built from.
 * Check out the BasicMenu class for an example of a child menu class that uses the 
 * 	functionality put together in here to make a working game menu.
 * 
 * @author Samuel Bumgardner
 */
class MenuTemplate implements UpdatingEntity implements HideableEntity implements Observed
{

	/**
	 * Variable to satisify UpdatingEntity interface.
	 * Determines whether this object should execute the body of its update function.
	 */
	public var active:Bool = false;
	
	/**
	 * Variable to satisfy Observed interface.
	 * Used to notify observers when input events occur.
	 */
	public var subject:Subject;
	
	/**
	 * x & y coordinates that all menu components should be positioned relative to.
	 * Can be changed by external entities using setX() and setY().
	 */
	private var x:Float;
	private var y:Float;
	
	/**
	 * FlxGroup that holds all HaxeFlixel-inheriting components used by this menu.
	 */
	public var totalFlxGrp(default, null):FlxGroup = new FlxGroup();
	
	/**
	 * FlxGroup that only holds the HaxeFlixel components from this menu's MenuOptions.
	 */
	private var optionFlxGrp:FlxGroup = new FlxGroup();
	
	/**
	 * Array of menuOption objects. At the moment, this is just used to find the
	 * first menu option whenever the menu is re-opened (so the cursor always starts
	 * at the same position every time). 
	 * 
	 * If it ends up not being used for anything else in this template, then it will
	 * be removed from here and added to any child classes that specifically need this
	 * functionality.
	 */
	private var menuOptionArr:Array<MenuOption> = new Array<MenuOption>();
	
	/**
	 * The menu option that the cursor is currently selecting/hovering over.
	 */
	private var currMenuOption:MenuOption;
	
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
	 * Sound effect to be played upon cursor movement.
	 */
	private var moveSound:FlxSound;
	private var confirmSound:FlxSound;
	private var cancelSound:FlxSound;
	
	/**
	 * Initializer.
	 * 
	 * @param	X			x-coordinate for the new menu.
	 * @param	Y			y-coordinate for the new menu.
	 * @param	subjectID	ID for this menu's Subject, used when events are notified. 
	 */
	public function new(?X:Float = 0, ?Y:Float = 0, ?subjectID:Int = 0)
	{
		x = X;
		y = Y;
		
		initSoundAssets();
		
		subject = new Subject(this, subjectID);
	}
	
	/**
	 * Loads all sound assets needed by this object.
	 */
	private function initSoundAssets():Void
	{
		moveSound = FlxG.sound.load(AssetPaths.menu_move__wav);
		confirmSound = FlxG.sound.load(AssetPaths.menu_confirm__wav);
		cancelSound = FlxG.sound.load(AssetPaths.menu_cancel__wav);
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Public function for changing the x position of the menu and all of its components.
	 * 
	 * @param	newX	The menu's new x value.
	 * @return	The menu's new x value.
	 */
	public function setX(newX:Float):Float
	{
		var xDiff:Float = newX - x;
		totalFlxGrp.forEach(moveSpriteX.bind(_, xDiff), true);
		
		for (menuOption in menuOptionArr)
		{
			menuOption.labelPos.add(xDiff, 0);
			menuOption.cursorPos.add(xDiff, 0);
		}
		menuCursor.moveAnchor(xDiff, 0);
		
		return x = newX;
	}
	
	/**
	 * Helper function used by setX().
	 * Is passed as the argument into an FlxGroup's forEach() to change the x values of all
	 * 	sprites in the menu's totalFlxGrp. 
	 * Because totalFlxGroup holds objects of type FlxBasic, the function has to test that the 
	 * 	"targetSprite" FlxBasic object is actually an FlxSprite (or something that inherits 
	 * 	from it) so it has an x component to change.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 * @param	dX				The amount the targetSprite's x should change by.
	 */
	private function moveSpriteX(targetSprite:FlxBasic, dX:Float):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).x += dX;
		}
	}
	
	/**
	 * Public function for changing the y position of the menu and all of its components.
	 * 
	 * @param	newY	The menu's new y value.
	 * @return	The menu's new y value.
	 */
	public function setY(newY:Float):Float
	{
		var yDiff = newY - y;
		totalFlxGrp.forEach(moveSpriteY.bind(_, yDiff), true);
		
		for (menuOption in menuOptionArr)
		{
			menuOption.labelPos.add(0, yDiff);
			menuOption.cursorPos.add(0, yDiff);
		}
		menuCursor.moveAnchor(0, yDiff);
		
		return y = newY;
	}
	
	/**
	 * Helper function used by setY().
	 * Is passed as the argument into an FlxGroup's forEach() to change the y values of all
	 * 	sprites in the menu's totalFlxGrp.
	 * Because totalFlxGroup holds objects of type FlxBasic, the function has to test that the 
	 * 	"targetSprite" FlxBasic object is actually an FlxSprite (or something that inherits 
	 * 	from it) so it has an y component to change.
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 * @param	dY				The amount that targetSprite's y should change by.
	 */
	private function moveSpriteY(targetSprite:FlxBasic, dY:Float):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).y += dY;
		}
	}
	
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
	 */
	public function hide():Void
	{
		totalFlxGrp.forEach(hideSprite, true);
		menuCursorTween.active = false;
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
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
	 * Also is responsible for calling reset menu to give the menu its initial appearance again.
	 */
	public function reveal():Void
	{
		totalFlxGrp.forEach(revealSprite, true);
		
		menuCursorTween.active = true;
		
		resetMenu();
	}
	
	/**
	 * Helper function for reveal().
	 * Also is responsible for resetting the menu's variables and appearance back to their
	 * 	starting states. This includes hiding the background higlight graphic of all menu
	 * 	options that are not initally hovered over in the menu.
	 * 
	 * NOTE: Assumes that there is at least one entry in menuOptionArr.
	 */
	private function resetMenu():Void
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
	
	/**
	 * Function to satisfy UpdatingEntity interface.
	 * Sets active variable to true, meaning that the body of this object's update function will
	 * 	run when called.
	 */
	public function activate():Void
	{
		active = true;
	}
	
	/**
	 * Function to satisfy UpdatingEntity interface.
	 * Sets active variable to false, meaning that the body of this object's update function will
	 * 	not be run when called.
	 */
	public function deactivate():Void
	{
		active = false;
	}
	
	
	///////////////////////////////////////
	//        BASIC CURSOR SETUP         //
	///////////////////////////////////////
	
	/**
	 * Creates the cursor anchor sprite and sets up a tween for it using cursorBounceFunc().
	 */
	private function initBasicCursor():Void
	{
		menuCursor = new AnchoredSprite(0, 0, AssetPaths.menu_cursor_simple__png);
		menuCursorTween = FlxTween.num(0, bounceDistance, .75, {ease: FlxEase.circInOut, 
			type: FlxTween.LOOPING}, cursorBounceFunc.bind(menuCursor));
		totalFlxGrp.add(menuCursor);
	}
	
	/**
	 * Tween function for use in a NumTween created in initBasicCursor().
	 * 
	 * Because HaxeFlixel doesn't allow looping chained tweens, I had to do a bit of a hacky
	 * function here to make the whole movement in a single tween. Basically, when the bounce
	 * is half over (offsetValue > corner.width /2) offsetValue is changed so it counts back to
	 * zero, making the first half move the cursor to the right, and the second half expand it
	 * again.
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
	 * Recieves a set of boolean input values and determines if movement should occur.
	 * If the movment is "held", it may follow an alternative set of rules.
	 */
	private function moveCursor(vertMove:Int, horizMove:Int, heldMove:Bool):Void
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
	 * 	notifying its observes that the event happened, and lets those observers take care
	 * 	of manipulation of external objects.
	 * 
	 * Is not expecting to ever get a call with heldAction being true (because of its call
	 * 	to ActionInputHandler, see below in the update function) but I set up the test at
	 * 	the start of the function just in case.
	 * 
	 * Can (and probably should) be overridden by child classes of this, since different
	 * 	menus may not need to notify PAINT, NEXT, or INFO events. If it is overridden with
	 * 	the intent to replace this function, make sure to NOT call super.doCursorAction();
	 * 
	 * @param	pressedKeys	Indicates which keys were pressed. Use KeyIndex enum (from ActionInputHandler) to identify what type of input each index corresponds to.
	 * @param	heldAction	Whether the provided set of pressed keys were held down for a length of time (true) or just pressed (false).
	 */
	private function doCursorAction(pressedKeys:Array<Bool>, heldAction:Bool)
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
	public function update(elapsed:Float):Void
	{
		if (active)
		{
			MoveInputHandler.handleMovement(elapsed, moveCursor);
			ActionInputHandler.handleActions(elapsed, doCursorAction, false);
			moveCursorAnchors();
		}
	}
}