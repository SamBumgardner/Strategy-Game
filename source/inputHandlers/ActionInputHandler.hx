package inputHandlers;
import flixel.FlxG;
import flixel.input.FlxInput.FlxInputState;
import flixel.input.keyboard.FlxKey;

/**
 * Action input handling-class used by all objects that need to recieve movement inputs,
 * 	whether they are a menu, map cursor, or something else entirely.
 * 
 * Overall, very similar to MoveInputHandler. See that class for an explanation for why
 * 	class with all static fields was used to handle inputs instead of some other system.
 * 
 * One major difference between the two classes is that this one requires the external 
 * 	caller to specify if held input should be attempted, since it seems reasonable to
 * 	expect that not all callers will want the repeating functionality.
 * 
 * NOTE:
 * 	User input handling follows this pattern of logic:
 * 		- When the user initially presses an action key, an action callback function
 * 			is called with the pressed key information passed along as parameters.
 * 		- Whenever any movement key is initially pressed or released, an internal 
 * 			timer (counting up, like a stopwatch) resets.
 * 		- If that internal timer is over a certain threshold value AND the initial call to
 * 			HandleActions specified that the held inputs should be attempted, the action callback
 * 			is called using the inputs that are currently held down. It is up to the object
 * 			that defined the callback function to use those inputs responsibly, since that 
 * 			callback function will be called every frame after the threshold has passed.
 * 
 * @author Samuel Bumgardner
 */
class ActionInputHandler
{
	
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Boolean value that indicates if init() has already been called to perform first-time setup.
	 */
	static public var initialized(default, null):Bool = false;
	
	/**
	 * Array that contains the set of action keys described in the enum below this class.
	 * For convenience, their function and index in the array will be listed here as well:
	 * 
	 * 	[0] Confirm
	 *  [1] Cancel 
	 *  [2] Paint
	 * 	[3] Next
	 * 	[4] Info
	 * 
	 * Using an array to hold keys around was ultimately much more convenient than
	 * 	passing around (and using) 5 different FlxKey variables. This should also be
	 * 	easier to maintain and alter if we decide to add/remove action inputs later.
	 */
	static private var keyArray:Array<FlxKey> = new Array<FlxKey>();
	
	/**
	 * The number of keys that should be in keyArray.
	 */
	static private var keyArrayLen(default, never):Int = 5;
	
	/**
	 * Array of boolean values that can be updated to reflect the status of each
	 * button, where true means that button is active, and false means inactive.
	 */
	static private var keyBools(default, null):Array<Bool> = new Array<Bool>();
	
	/**
	 * Tracks if any new inputs have been entered in this frame.
	 * Used in processActionInput() and attemptHeldAction().
	 */
	static private var actionInputChanged:Bool = false;
	
	/**
	 * Tracks the total amount of time that the current set of directional inputs
	 * 	have been held for. Used in attemptHeldAction().
	 */
	static private var timeMoveHeld:Float = 0;
	
	/**
	 * The minimum amount of time the button must be held to start continuously moving.
	 */
	static private var timeMoveHeldThreshold(default, null):Float = .25;
	
	/**
	 * Boolean variable that tracks whether an object has already used input-handling 
	 * 	functionality this frame. If so, then the input-handling function shouldn't be
	 * 	called again (on this frame).
	 */
	static private var alreadyCalledThisFrame:Bool;
	
	public function new() {}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Performs one-time setup for this class's arrays.
	 * Must be called before this class is actually used to handle inputs.
	 * 
	 * The key array should contain the keys in this order:
	 * 
	 * 	[0] Confirm
	 *  [1] Cancel 
	 *  [2] Paint
	 * 	[3] Next
	 * 	[4] Info
	 * 
	 * @param	initialKeyArray	Array of keys that to be passed into the first call of setActionKeys().
	 */
	static public function init(initialKeyArray:Array<FlxKey>):Void
	{
		if (!initialized)
		{
			setActionKeys(initialKeyArray);
			
			for (i in 0...keyArrayLen)
			{
				keyBools.push(false);
			}
			
			initialized = true;
		}
		else
		{
			trace("ERROR: ActionInputHandler's init() has already been called!");
		}
	}
	
	/**
	 * Sets keyArray to match the provided array, which should be arranged in the following 
	 * 	order:
	 * 
	 *  [0] Confirm
	 *  [1] Cancel 
	 *  [2] Paint
	 * 	[3] Next
	 * 	[4] Info
	 * 
	 * If the length of the provided array does not equal 5, no input re-assigning will occur.
	 * 
	 * @param	newKeyArray	New set of 5 keys to use as action inputs.
	 */
	static public function setActionKeys(newKeyArray:Array<FlxKey>):Void
	{
		if (newKeyArray.length != keyArrayLen)
		{
			trace("ERROR: Provided incorrect number of keys to setActionKeys().");
		}
		else
		{	
			keyArray = newKeyArray;
		}
	}
	
	/**
	 * Main point of interaction between ActionInputHandler and any classes that want
	 * 	to move. Goes through the process of attempting pressed and/or held actions,
	 * 	and cleans up its own variables.
	 * 
	 * NOTE: Should only be called once per update cycle, otherwise held input will
	 * 	not function as intended (and multiple objects will be consuming the same inputs).
	 * 
	 * @param	elapsed			Time since last call to this function, in seconds.
	 * @param	actionCallback	Fuction that defines how action inputs should be used.
	 * @param	attemptHeld		Determines whether held inputs should be processed or ignored.
	 */
	static public function handleActions(elapsed:Float, actionCallback:Array<Bool>->Bool->Void,
		attemptHeld:Bool):Void
	{
		if (!initialized)
		{
			trace("ERROR: Called handleActions() before performing first-time initialization.");
		}
		
		if (alreadyCalledThisFrame)
		{
			trace("ERROR: ActionInputHandler's handleActions() was already called this frame",
				"\n or forgot to call updateCycleFinished().");
		}
		
		attemptPressedAction(actionCallback);
		if (attemptHeld)
		{
			attemptHeldAction(elapsed, actionCallback);
		}
		cleanupVariables();
		
		alreadyCalledThisFrame = true;
	}
	
	/**
	 * Resets the (non-key) variables of the ActionInputHandler back to their original values,
	 * 	so held movement doesn't carry over when transitioning between menus.
	 * 
	 * Should be called by an external class whenever the object interacting with the
	 * 	ActionInputHandler changes.
	 */
	static public function resetNumVars():Void
	{
		actionInputChanged = false;
		timeMoveHeld = 0;
	}
	
	/**
	 * Resets alreadyCalledThisFrame, which is used to check if multiple objects
	 * 	are trying to use ActionInputHandler on the same frame (which would be bad).
	 * 
	 * Should be called by the current scene at the end of its update function.
	 */
	static public function updateCycleFinished():Void
	{
		alreadyCalledThisFrame = false;
	}
	
	
	///////////////////////////////////////
	//       ACTION INPUT HANDLING       //
	///////////////////////////////////////
	
	/**
	 * Identifies if a new action input was pressed this frame. 
	 * If so, it sets actionInputChanged to true and attempts that action.
	 * 
	 * @param	actionCallback	Function that should be called to attempt actions.
	 */
	static private function attemptPressedAction(actionCallback:Array<Bool>->Bool->Void):Void
	{
		if (FlxG.keys.anyJustPressed(keyArray) || FlxG.keys.anyJustReleased(keyArray))
		{
			actionInputChanged = true;
			actionCallback(findInputBools(FlxInputState.JUST_PRESSED), false);
		}	
	}
	
	/**
	 * Identifies if the current action inputs have been held down for some time.
	 * If it has been held without changes for long enough, then it will attempt to
	 * act upon those inputs every frame.
	 * 
	 * The actionCallback is responsible for handling held actions. Held buttons will be 
	 * 	reported every frame, which is probably far more frequent than the caller wants to 
	 * 	actually do something because an input was held.
	 * 
	 * NOTE: It may not matter in the long run, but the "held action" test also passes
	 * 	if the player isn't holding any buttons at all for long enough, which may not be
	 * 	desired behavior.
	 * 
	 * @param	elapsed			Time elapsed since the last call to this in seconds.
	 * @param	actionCallback	Function that should be called to attempt actions.
	 */
	static private function attemptHeldAction(elapsed:Float, actionCallback:Array<Bool>->Bool->Void):Void
	{
		if (!actionInputChanged)
		{
			if(!alreadyCalledThisFrame)
			{
				timeMoveHeld += elapsed;
			}
			
			if (timeMoveHeld > timeMoveHeldThreshold)
			{
				actionCallback(findInputBools(FlxInputState.PRESSED), true);
			}
		}
		else
		{
			timeMoveHeld = 0;
		}
	}
	
	/**
	 * Sets the values of the keyBools array to true/false according to the key's status
	 * 	and the input status provided as a parameter, then returns keyBools for external
	 * 	use.
	 * 
	 * @param	inputStatus	The status to check 
	 * @return	Array of boolean values that correspond to the FlxKeys in keyArray.
	 */
	static private function findInputBools(inputStatus:FlxInputState):Array<Bool>
	{
		for (i in 0...keyArrayLen)
		{
			keyBools[i] = FlxG.keys.checkStatus(keyArray[i], inputStatus);
		}
		
		return keyBools;
	}
	
	/**
	 * Handles resetting any variables necessary at the end of calling movement functions.
	 */
	static private function cleanupVariables():Void
	{
		actionInputChanged = false;
	}
}
	
/**
 * This enum makes it clear what sort of input each index of the keyArray corresponds to.
 */
@:enum
class KeyIndex
{
	public static var CONFIRM	(default, never) = 0;
	public static var CANCEL	(default, never) = 1;
	public static var PAINT		(default, never) = 2;
	public static var NEXT		(default, never) = 3;
	public static var INFO		(default, never) = 4;
}