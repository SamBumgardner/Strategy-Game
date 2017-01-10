package utilities;

/**
 * Functions to be used on InputEvent-type variables to set and get its fields.
 * 
 * =========
 * 
 * 	Current InputEvent Format in hexadecimal:
 * 		0xAAAABBBB
 * 	The "A" field denotes event type (typically what kind of input triggered the event)
 * 	The "B" field denotes subject ID.
 * 
 * 	Assumes that the event type is in the range 0 - 65,535;
 * 	Assumes that ID is in the range 0 - 65,535;
 * 
 * =========
 * 
 * NOTE: The line 'using utilities.EventExtender' must be added to the top of any file
 * 	where these functions are used on InputEvent objects. See the 'Static Extension'
 * 	page of the haxe manual (https://haxe.org/manual/lf-static-extension.html) for 
 * 	an explanation of how this will be used.
 * 
 * @author Samuel Bumgardner
 */
 
class EventExtender 
{	
	/**
	 * Uses bitwise operations to store the provided id in the first 16 bits of an event.
	 * 
	 * @param	event	The InputEvent object being altered.
	 * @param	id		Integer in range 0 - 65,535. Behavior is undefined if outside of range.
	 * @return	The altered InputEvent.
	 */
	static public function setID(event:InputEvent, id:Int):InputEvent
	{
		return (event & 0xFFFF0000) | id;
	}
	
	/**
	 * Uses bitwise operations to return the id of the InputEvent, which was stored in its
	 * 	first 16 bits.
	 * 
	 * @param	event	The InputEvent object being read from.
	 * @return	The id value from the first 16 bits of the InputEvent.
	 */
	static public function getID(event:InputEvent):Int
	{
		return event & 0x0000FFFF;
	}
	
	/**
	 * Uses bitwise operations to store the provided type info in the last 16 bits of an event.
	 * 
	 * @param	event	The InputEvent object being altered.
	 * @param	type	Integer in range 0 - 65,535. Behavior is undefined if outside of range.
	 * @return	The altered InputEvent.
	 */
	static public function setType(event:InputEvent, type:Int):InputEvent
	{
		return (event & 0x0000FFFF) | (type << 16);
	}
	
	/**
	 * Uses bitwise operations to return the type of the InputEvent, which was stored in its
	 * 	last 16 bits.
	 * 
	 * @param	event	The InputEvent object being read from.
	 * @return	The type value from the last 16 bits of the InputEvent.
	 */
	static public function getType(event:InputEvent):Int
	{
		return (event & 0xFFFF0000) >> 16;
	}
}