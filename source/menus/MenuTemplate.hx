package menus;

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
import observerPattern.eventSystem.EventTypes;
import utilities.HideableEntity;
import observerPattern.Observed;
import observerPattern.Subject;
import utilities.LogicalContainer;
import utilities.LogicalContainerNester;
import utilities.UpdatingEntity;

/**
 * Base class for all other menu classes to inherit from.
 * 
 * Lays out the base logic for important menu functions, including:
 * 	- Containing MenuOptions.
 * 	- Hiding menu and all components.
 * 	- Activating/Deactivating menu.
 * 	- Reacting to user "move" and "action" input.
 * 		- Uses observer pattern-style system, using its Subject component to notify observers.
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
	implements LogicalContainerNester
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
	 * Can be changed by external entities using setPos().
	 */
	public var x(default, null):Float;
	public var y(default, null):Float;
	
	/**
	 * The scroll factor to be used by all visual components of a menu.
	 * Is set to zero because menus should always appear at the same point
	 * 	on the screen regardless of camera position.
	 */
	private var menuScrollFactor(default, never):FlxPoint = new FlxPoint(0, 0);
	
	/**
	 * FlxGroup that holds all HaxeFlixel-inheriting components used by this menu.
	 */
	public var totalFlxGrp(default, null):FlxGroup = new FlxGroup();
	
	/**
	 * Array of logical containers that will need logical position updates when this object's
	 *  logical position updates.
	 */
	public var nestedContainers(null, null):Array<LogicalContainer> = new Array<LogicalContainer>();
	
	/**
	 * Sound effects to be played after cursor actions.
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
	
	/**
	 * Adds all of the menu's different FlxGrps to its totalFlxGrp in the correct order.
	 * The order matters because the first item added to totalFlxGrp will be drawn on the
	 * 	bottom layer, the next is drawn one layer above it, and so on.
	 * 
	 * The body of this function is left empty, and is expected to be overloaded and used
	 * 	by all child classes in whatever manner is appropriate for that particular menu.
	 * 
	 * See the BasicMenu class for an example implementation of this function.
	 */
	private function addAllFlxGrps():Void {}
	
	/**
	 * Sets the scroll factors of all sprites in totalFlxGrp to (0, 0).
	 * Must be called by child classes during initalization after calling addAllFlxGrps().
	 */
	private function setScrollFactors():Void
	{
		totalFlxGrp.forEach(setSpriteScroll, true);
	}
	
	/**
	 * Helper function for setScrollFactors().
	 * Determines if the targetSprite is an FlxSprite, and if so sets its scrollFactor
	 * 	to match the menuScrollFactor, which is (0, 0).
	 * 
	 * @param	targetSprite	The FlxBasic object that is being operated upon.
	 */
	private function setSpriteScroll(targetSprite:FlxBasic):Void
	{
		if (Std.is(targetSprite, FlxSprite))
		{
			(cast targetSprite).scrollFactor = menuScrollFactor;
		}
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
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
	
	/**
	 * Function to satisify HideableEntity interface.
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
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
	 * Is used to make all visual components within the menu's totalFlxGrp invisible and inactive.
	 * Also is responsible for calling reset menu to give the menu its initial appearance again.
	 */
	public function reveal():Void
	{
		totalFlxGrp.forEach(revealSprite, true);
		
		resetMenu();
	}
	
	/**
	 * Helper function for reveal().
	 * Is responsible for resetting the menu's variables and appearance back to their
	 * 	starting states. 
	 * 
	 * The body of this function is left empty, and is expected to be overloaded and used
	 * 	by all child classes in whatever manner is appropriate for that particular menu.
	 */
	private function resetMenu():Void {}
	
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
	//         MOVEMENT RESPONSE         //
	///////////////////////////////////////
	
	/**
	 * Recieves a set of boolean input values and determines if movement should occur.
	 * If the movment is "held", it may follow an alternative set of rules.
	 * 
	 * This function should be overriden by all child classes to set up their desired
	 * 	functionailty.
	 * 
	 * @param	vertMove	indicates presence and direction of vertical movement input.
	 * @param	horizMove	indicates presence and direction of horizontal movement input.
	 * @param	heldMove	indicates whether the movement input was "held" or pressed this frame.
	 */
	private function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void {}
	
	
	///////////////////////////////////////
	//          ACTION RESPONSE          //
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
	 * @param	pressedKeys	Indicates which keys were pressed. Use KeyIndex enum (from 
	 * 			ActionInputHandler) to identify what type of input each index corresponds to.
	 * 
	 * @param	heldAction	Whether the provided set of pressed keys were held down for a 
	 * 			length of time (true) or just pressed (false).
	 */
	private function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool):Void {}
	
	
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
			MoveInputHandler.handleMovement(elapsed, moveResponse);
			
			while (active && 
				ActionInputHandler.actionBuffer.length > ActionInputHandler.numInputsUsed)
			{
				ActionInputHandler.useBufferedInput(actionResponse);
			}
		}
	}
}