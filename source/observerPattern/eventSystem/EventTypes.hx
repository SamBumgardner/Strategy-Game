package observerPattern.eventSystem;

/**
 * Enum defining the different types of input events that can occur.
 * These are the values that should be passed into the Subject class when notifying an event,
 * 	and these are the values that should be used when doing any comparisons to test the type field
 * 	of an InputEvent object.
 * 
 * @author Samuel Bumgardner
 */

@:enum
class EventTypes 
{
	public static var NO_TYPE(default, never)  = -1;
	public static var CONFIRM(default, never)  = 0;
	public static var CANCEL(default, never)   = 1;
	public static var PAINT(default, never)    = 2;
	public static var NEXT(default, never)     = 3;
	public static var INFO(default, never)     = 4;
	public static var MOVE(default, never)     = 5;
}