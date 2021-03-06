package inputHandlers;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

/**
 * Movement input handling-class used by all objects that need to recieve movement
 * 	inputs, whether they are a menu or map cursor.
 * 
 * This functionality is in a static functions of a class (pretty much a singleton)
 * 	because it feels like the cleanest way to implement this functionality that is
 * 	going to be shared by a pretty hefty number of different game elements.
 * 
 * I considered using inheritance (all movement-input-parsing objects could inherit
 * 	from a acceptsMoveInput class, for example) but that could eventually cause problems
 * 	with classes that also need to accept other types of input, like affirmative/negative
 * 	inputs, in addition to movement inputs. Since Haxe doesn't allow multiple inheritance,
 * 	I would have to do something weird to make an object that accepts both sorts of inputs,
 * 	such as creating a version of the affirmative/negative input class that inherits from
 * 	the movement input class of vice versa, then creating a standalone version of the 
 * 	affirmative/negative class for child classes that don't need the movement functionality. 
 * 
 * That seemed like a big, difficult-to-avoid mess, so I decided to do this singleton
 * 	strategy instead. As long as I make sure to only have one external object interacting
 * 	with this class at any given time, this should be a safe and effective way to implement
 * 	movement that cuts down on redundant code.
 * 
 * NOTE:
 * 	User input handling follows this pattern of logic:
 * 		- When the user initially presses a movement key, a movement callback function
 * 			is called with the pressed key information passed along as parameters.
 * 		- Whenever any movement key is initially pressed or released, an internal 
 * 			timer (counting up, like a stopwatch) resets.
 * 		- If that internal timer is over a certain threshold value, the movement callback
 * 			is called using the inputs that are currently held down. It is up to the object
 * 			that defined the callback function to use those inputs responsibly, since that 
 * 			callback function will be called every frame after the threshold has passed.
 * 
 * @author Samuel Bumgardner
 */

class MoveInputHandler
{
	
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Boolean value that indicates if init() has already been called to perform first-time setup.
	 */
	static public var initialized(default, null):Bool = false;
	
	/**
	 * Tracks if any new inputs have been entered in this frame.
	 * 	Used in processMovementInput() and attemptHeldMovement()
	 */
	static private var moveInputChanged:Bool = false;
	
	/**
	 * Tracks the total amount of time that the current set of directional inputs
	 * 	have been held for. Used in attemptHeldMovement().
	 */
	static private var timeMoveHeld:Float = 0;
	
	/**
	 * The minimum amount of time the button must be held to start continuously moving.
	 */
	static private var timeMoveHeldThreshold(default, null):Float = .2;

	/**
	 * Set of keys that are used as directional inputs for movement. 
	 * Can be changed through a public function, which means that key rebinding is allowed!
	 */
	static private var upKey:FlxKey;
	static private var downKey:FlxKey; 
	static private var leftKey:FlxKey;
	static private var rightKey:FlxKey;
	
	/**
	 * Boolean variable that tracks whether an object has already used input-handling 
	 * 	functionality this frame. If so, then the input-handling function shouldn't be
	 * 	called again (on this frame). Technically you can, but held behavior may not 
	 * 	function exactly as desired. That, and multiple objects will be consuming the 
	 * 	same inputs.
	 */
	static private var alreadyCalledThisFrame:Bool;
	
	public function new() {}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Function that performs first-time setup for MoveInputHandler.
	 * Must be called before this class is actually used to handle inputs.
	 * 
	 * @param	up		Initial key used for "up" input.
	 * @param	down	Initial key used for "down" input.
	 * @param	left	Initial key used for "left" input.
	 * @param	right	Initial key used for "right" input.
	 */
	static public function init(up:FlxKey, down:FlxKey, left:FlxKey, right:FlxKey)
	{
		setMoveKeys(up, down, left, right);
		initialized = true;
	}
	
	/**
	 * Recieves FlxKeys, then adjusts its internal variables to match that
	 * 	new set of FlxKeys.
	 * 
	 * @param	newUp		New key to indicate "up" movement.
	 * @param	newDown		New key to indicate "down" movement.
	 * @param	newLeft		New key to indicate "left" movement.
	 * @param	newRight	New key to indicate "right" movement.
	 */
	static public function setMoveKeys(newUp:FlxKey, newDown:FlxKey, newLeft:FlxKey, 
		newRight:FlxKey):Void
	{
		upKey = newUp;
		downKey = newDown;
		leftKey = newLeft;
		rightKey = newRight;
	}
	
	/**
	 * Resets the (non-key) variables of the MoveInputHandler back to their original values,
	 * 	so held movement doesn't carry over when transitioning between menus.
	 * 
	 * Should be called by an external class whenever the object interacting with the
	 * 	MoveInputHandler changes.
	 */
	static public function resetNumVars():Void
	{
		moveInputChanged = false;
		timeMoveHeld = 0;
	}
	
	/**
	 * Main point of interaction between MoveInputHandler and any classes that want
	 * 	to move. Goes through the process of attempting pressed and held movement,
	 * 	and cleans up its own variables.
	 * 
	 * NOTE: Should only be called once per update cycle, otherwise held input will
	 * 	not function as intended (and multiple objects will be consuming the same inputs).
	 * 
	 * @param	elapsed			Time since last call to this function, in seconds.
	 * @param	moveCallback	Function that defines how movement inputs should be used.
	 */
	static public function handleMovement(elapsed:Float, moveCallback:Int->Int->Bool->Void):Void
	{
		if (!initialized)
		{
			trace("ERROR: Called handleMovement() before performing first-time initialization.");
		}
		
		if (alreadyCalledThisFrame)
		{
			trace("ERROR: MoveInputHandler's handleMovement() was already called this frame",
					"\n or forgot to call updateCycleFinished().");
		}
		
		attemptPressedMovement(moveCallback);
		attemptHeldMovement(elapsed, moveCallback);
		cleanupVariables();
		
		alreadyCalledThisFrame = true;
	}
	
	/**
	 * Resets alreadyCalledThisFrame, which is used to check if multiple objects
	 * 	are trying to use MoveInputHandler on the same frame (which would be bad).
	 * 
	 * Should be called by the current scene at the end of its update function.
	 */
	static public function updateCycleFinished():Void
	{
		alreadyCalledThisFrame = false;
	}
	
	
	///////////////////////////////////////
	//      MOVEMENT INPUT HANDLING      //
	///////////////////////////////////////
	
	/**
	 * Recieves a set of boolean input values and determines if movement should occur.
	 * If the movment is "held", it may follow an alternative set of rules.
	 * 
	 * @param	upInput			Boolean value indicating an "up" input.
	 * @param	downInput		Boolean value indicating a "down" input.
	 * @param	leftInput		Boolean value indicating a "left" input.
	 * @param	rightInput		Boolean value indicating a "right" input.
	 * @param	heldMove		Boolean value indicating if inputs are "pressed" or "held".
	 * @param	moveCallback	Function to be called with the results of inputs.
	 */
	static private function processMovementInput(upInput:Bool, downInput:Bool, leftInput:Bool, 
		rightInput:Bool, heldMove:Bool, moveCallback:Int->Int->Bool->Void):Void
	{
		var vertMove:Int	= 0;
		var horizMove:Int	= 0;
		
		if (upInput)
		{
			vertMove--;
		}
		if (downInput)
		{
			vertMove++;
		}
		if (leftInput)
		{
			horizMove--;
		}
		if (rightInput)
		{
			horizMove++;
		}
		
		if (vertMove != 0 || horizMove != 0)
		{
			moveCallback(vertMove, horizMove, heldMove);
		}
	}
	
	/**
	 * Identifies if a new movement input was pressed this frame. 
	 * If so, it sets moveInputChanged to true and attempts movement.
	 * 
	 * @param	moveCallback	Function to be passed along to processMovementInput. Defines how movement inputs should be used.
	 */
	static private function attemptPressedMovement(moveCallback:Int->Int->Bool->Void):Void
	{
		if (FlxG.keys.anyJustPressed([upKey, downKey, leftKey, rightKey]) ||
			FlxG.keys.anyJustReleased([upKey, downKey, leftKey, rightKey]))
		{
			moveInputChanged = true;
			processMovementInput(FlxG.keys.checkStatus(upKey, JUST_PRESSED), 
				FlxG.keys.checkStatus(downKey, JUST_PRESSED), 
				FlxG.keys.checkStatus(leftKey, JUST_PRESSED), 
				FlxG.keys.checkStatus(rightKey, JUST_PRESSED), false, moveCallback);
		}	
	}
	
	/**
	 * Identifies if the current movement inputs have been held down for some time,
	 * if it has been held without changes for long enough, then it will attempt to
	 * move in the held direction.
	 * 
	 * The caller is responsible for handling held movement. Held buttons will be reported
	 * 	every frame, which is probably far more frequent than the caller wants to actually
	 * 	do something because an input was held.
	 * 
	 * NOTE: It may not matter in the long run, but the "held movement" test also passes
	 * 	if the player isn't holding any buttons at all for long enough, which may not be
	 * 	desired behavior.
	 * 
	 * @param	elapsed	The amount of time since the last atteptHeldMovement in seconds.
	 * @param	moveCallback	Function to be passed along to processMovementInput. Defines how movement inputs should be used.
	 */
	static private function attemptHeldMovement(elapsed:Float, moveCallback:Int->Int->Bool->Void):Void
	{
		if (!moveInputChanged)
		{
			if(!alreadyCalledThisFrame)
			{
				timeMoveHeld += elapsed;
			}
			
			if (timeMoveHeld > timeMoveHeldThreshold)
			{
				processMovementInput(FlxG.keys.checkStatus(upKey, PRESSED), 
				FlxG.keys.checkStatus(downKey, PRESSED), 
				FlxG.keys.checkStatus(leftKey, PRESSED), 
				FlxG.keys.checkStatus(rightKey, PRESSED), true, moveCallback);
			}
		}
		else
		{
			timeMoveHeld = 0;
		}
	}
	
	/**
	 * Handles resetting any variables necessary at the end of calling movement functions.
	 */
	static private function cleanupVariables():Void
	{
		moveInputChanged = false;
	}
}