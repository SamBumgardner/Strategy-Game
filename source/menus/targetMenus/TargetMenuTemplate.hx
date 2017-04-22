package menus.targetMenus;
import cursors.MapCursor;
import flixel.FlxG;
import inputHandlers.ActionInputHandler;
import inputHandlers.ActionInputHandler.KeyIndex;
import inputHandlers.MoveInputHandler;
import menus.MenuTemplate;
import missions.MissionState;
import observerPattern.eventSystem.EventTypes;
import units.Unit;
import utilities.OnMapEntity;

using units.movement.MoveIDExtender;

/**
 * Base class for all other target-based menu classes to inherit from.
 * 
 * Lays out the base logic for important target menu functions, including:
 * 	- Creating the static targetCursor used by all target-type menus
 * 	- Revealing, hiding, activating, and deactivating target menus (and their cursor)
 *  - Typical handling of move events to cycle through possible targets.
 *  - Typical handling of action inputs for a target menu.
 * 
 * This class inherits additional menu properties/functions from its parent class, MenuTemplate.
 * See its child classes, such as AttackTargetMenu, HealTargetMenu, etc.
 * 
 * @author Samuel Bumgardner
 */
class TargetMenuTemplate extends MenuTemplate
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Array of the menu's current potential targets.
	 */
	public var possibleTargets(default, null):Array<OnMapEntity>;
	
	/**
	 * The currently targeted index in the possibleTargets array.
	 */
	private var targetIndex(default, set):Int;
	
	/**
	 * Reference to the object currently targeted by this menu.
	 * Children of this class will likely have to cast this variable to a more specific
	 *  type to get the most of using this particular variable.
	 */
	public var currentTarget(default, set):OnMapEntity;
	
	/**
	 * Static reference to the targetCursor used by all MapCursor objects.
	 */
	public static var targetCursor:MapCursor;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer
	 */
	public function new(ID:Int) 
	{
		super(0, 0, ID);
		
		// Do one-time initialization of the static targetCursor.
		if (targetCursor == null)
		{
			initTargetCursor();
		}
	}
	
	/**
	 * Initializes the static targetCursor used by all descendants of targetMenuTemplate.
	 */
	private function initTargetCursor():Void
	{
		targetCursor = new MapCursor((cast FlxG.state).map.width, (cast FlxG.state).map.height, 1);
		targetCursor.changeCursorType(CursorTypes.TARGET);
		targetCursor.changeMovementModes(MoveModes.BOUNCE_IN_OUT);
		targetCursor.changeInputModes(InputModes.DISABLED);
		targetCursor.hide();
	}
	
	
	///////////////////////////////////////
	//         SETTER FUNCTIONS          //
	///////////////////////////////////////
	
	/**
	 * Setter function for targetIndex.
	 * 
	 * When targetIndex changes, this function makes sure that currentTarget is also changed
	 *  to match. currentTarget should reference the object from the possibleTargets array at 
	 *  the new targetIndex.
	 * 
	 * It is also responsible for instructing the targetCursor to move to the current target's
	 *  row and column.
	 * 
	 * @param	newIndex	The new value for targetIndex.
	 */
	private function set_targetIndex(newIndex:Int):Int
	{
		targetIndex = newIndex;
		currentTarget = possibleTargets[targetIndex];
		targetCursor.moveToPosition(currentTarget.mapPos.getRow(), currentTarget.mapPos.getCol());
		return targetIndex;
	}
	
	/**
	 * Setter function for currentTarget. Doesn't do anything unusual in this class.
	 * 
	 * Should be overridden in child classes to use the newUnit's info to change 
	 * whatever information is displayed.
	 * 
	 * @param	newTarget	The new OnMapEntity object that currentTarget should reference.
	 */
	private function set_currentTarget(newTarget:OnMapEntity):OnMapEntity
	{
		return currentTarget = newTarget;
	}
	
	
	///////////////////////////////////////
	//          PUBLIC INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Overrides behavior from MenuTemplate.
	 * Makes the menu and its components visible.
	 */
	public override function reveal():Void
	{
		super.reveal();
		targetCursor.reveal();
	}
	
	/**
	 * Overrides behavior from MenuTemplate.
	 * Makes the menu and its components execute the contents of their update functions.
	 */
	public override function activate():Void
	{
		super.activate();
		targetCursor.activate();
	}
	
	/**
	 * Overrides behavior from MenuTemplate.
	 * Makes the menu and its components invisible.
	 */
	public override function hide():Void
	{
		super.hide();
		targetCursor.hide();
	}
	
	/**
	 * Overrides behavior from MenuTemplate.
	 * Prevents the menu and its components from executing the contents of their update functions.
	 */
	public override function deactivate():Void
	{
		super.deactivate();
		targetCursor.deactivate();
	}
	
	/**
	 * Calls functions from external classes to identify the currently selected unit's set 
	 *  of eligible targets.
	 * Logic should be handled in child classes.
	 */
	public function refreshTargets(parentState:MissionState):Void {}
	
	
	///////////////////////////////////////
	//   MISC. MENU TEMPLATE OVERRIDES   //
	///////////////////////////////////////
	
	/**
	 * Resets the target menu back to its starting state.
	 * Should typically be called just before displaying the menu.
	 */
	private override function resetMenu():Void
	{
		targetIndex = 0;
		targetCursor.jumpToPosition(currentTarget.mapPos.getRow(), currentTarget.mapPos.getCol());
	}
	
	
	///////////////////////////////////////
	//         MOVEMENT RESPONSE         //
	///////////////////////////////////////
	
	/**
	 * Recieves a set of int input values and determines if movement should occur.
	 * Left/up inputs have negative vert/horizMove values, while right/down have positive values.
	 * 
	 * If the sum of horizontal & vertical movement is positive or negative, then the targetIndex
	 *  increments or decrements and the currentTarget is updated accordingly.
	 * 
	 * Note: Held inputs are ignored unless the cursor isn't already moving, so the current
	 *  target won't change every frame during held movement. Pressed movements, meanwhile,
	 *  are never ignored.
	 * 
	 * @param	vertMove	indicates presence and direction of vertical movement input.
	 * @param	horizMove	indicates presence and direction of horizontal movement input.
	 * @param	heldMove	indicates whether the movement input was "held" or pressed this frame.
	 */
	private override function moveResponse(vertMove:Int, horizMove:Int, heldMove:Bool):Void 
	{
		// Check if there are multiple targets to move between.
		if (possibleTargets.length > 1)
		{
			// If the movement button is held, it can only move a stopped targetCursor.
			if (!heldMove || !targetCursor.isMoving)
			{
				if (horizMove + vertMove > 0)
				{
					targetIndex = (targetIndex + 1) % possibleTargets.length;
					moveSound.play(true);
				}
				else if (horizMove + vertMove < 0)
				{
					if (targetIndex != 0)
					{
						targetIndex = targetIndex - 1;
					}
					else
					{
						targetIndex = possibleTargets.length - 1;
					}
					moveSound.play(true);
				}
			}
		}
	}
	
	
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
	 * 	menus may need to notify a different set of events. If it is overridden with
	 * 	the intent to replace this function, make sure to NOT call super.actionResponse();
	 * 
	 * @param	pressedKeys	Indicates which keys were pressed. Use KeyIndex enum (from ActionInputHandler) to identify what type of input each index corresponds to.
	 * @param	heldAction	Whether the provided set of pressed keys were held down for a length of time (true) or just pressed (false).
	 */
	override private function actionResponse(pressedKeys:Array<Bool>, heldAction:Bool)
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
			else if (pressedKeys[KeyIndex.INFO])
			{
				subject.notify(EventTypes.INFO);
			}
		}
	}
	
	
	///////////////////////////////////////
	//          UPDATE FUNCTION          //
	///////////////////////////////////////
	
	/**
	 * Update function.
	 * 
	 * Buffered action inputs are only consumed when the target cursor has finished moving.
	 * Movement input is always handled. See moveResponse for details.
	 * 
	 * Also calls targetCursor's update(), since MapCursors aren't flixel-inheriting objects
	 *  that can just be added to the current state and have its update be handled automatically.
	 * 
	 * @param	elapsed	Time passed since last call to update (in seconds).
	 */
	override public function update(elapsed:Float):Void
	{
		
		if (active)
		{
			if (!targetCursor.isMoving)
			{
				// Call all of the buffered action functions in order.
				while (active && 
					ActionInputHandler.actionBuffer.length > ActionInputHandler.numInputsUsed)
				{
					ActionInputHandler.useBufferedInput(actionResponse);
				}
			}
			
			MoveInputHandler.handleMovement(elapsed, moveResponse);
			
			targetCursor.update(elapsed);
		}
	}
	
}