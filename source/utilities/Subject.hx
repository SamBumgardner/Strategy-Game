package utilities;

import utilities.InputEvent;
import utilities.EventExtender;

using utilities.EventExtender;

/**
 * Basic class for subjects in the Observer design pattern.
 * @author Samuel Bumgardner
 */
class Subject
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Array of Observer-type objects that should be notified whenever an event occurs.
	 * Used in the notify() function.
	 */
	private var observers:Array<Observer> = new Array<Observer>();
	
	/**
	 * Integer identifier for this particular subject. Is sent along with the event type
	 * 	whenever an event is notified, making it easier for Observers to identify which
	 * 	object just notified an event.
	 */
	public var ID(default, set):Int;
	
	/**
	 * The object that this Subject is composed within. A reference to this parent object
	 * 	is also sent with all notifications, so the observer can gather any additional info
	 * 	from the parent object that is needed to interpret the event. i.e. could be used to
	 * 	identify which entry of a menu a cursor is pointing at.
	 */
	public var parentObject:Observed;
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	parent	The object that this Subject is composed within.
	 * @param	id	Integer used to set the id of this subject.
	 */
	public function new(parent:Observed, ?id:Int = 0) 
	{
		parentObject = parent;
		ID = id;
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Setter function for the public ID variable.
	 * Not exactly necessary right now, but could be a nice spot to drop in some trace()
	 * 	statements during future debugging.
	 * 
	 * @param	newID	Value that the subject's ID should be set to.
	 * @return	The new ID.
	 */
	public function set_ID(newID:Int):Int
	{
		return ID = newID;
	}
	
	/**
	 * Adds Observer to the end of the subject's observers array.
	 * 
	 * @param	obs	The Observer object to push onto the array.
	 */
	public function addObserver(obs:Observer):Void
	{
		observers.push(obs);
	}
	
	/**
	 * Removes Observer object from te subject's observers array.
	 * 
	 * @param	obs	The Observer object to remove from the array.
	 */
	public function removeObserver(obs:Observer):Void
	{
		observers.remove(obs);
	}
	
	/**
	 * Calls the notify function on every Observer in the observers array.
	 * 
	 * @param	eventType	The type of input that triggered the event. Should come from the EventTypes enum.
	 */
	public function notify(eventType:Int):Void
	{
		var e:InputEvent = 0;
		e = e.setID(ID).setType(eventType);
		
		for (obs in observers)
		{
			obs.onNotify(e, parentObject);
		}
	}
}