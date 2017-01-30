package missions.managers;

import cursors.MapCursor;
import flixel.FlxG;
import observerPattern.Observed;
import observerPattern.Observer;
import observerPattern.eventSystem.EventTypes;
import observerPattern.eventSystem.InputEvent;

using observerPattern.eventSystem.EventExtender;

/**
 * A component of MissionState that acts as a middleman between MissionState 
 * 	and MapCursor to reduce the complexity of MissionState's code.
 * 
 * Responsible for managing the MissionState's MapCursor object.
 * 	This includes detecting and responding to events from the mapCursor.
 * 
 * @author Samuel Bumgardner
 */
class MapCursorManager implements Observer
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * The MissionState object that created this manager.
	 * Used to access information about the current mission and to call
	 * 	functions as needed to cause changes on the overall MissionState.
	 */
	public var parentState:MissionState;
	
	/**
	 * The MapCursor that this manager is responsible for controlling.
	 */
	public var mapCursor:MapCursor;
	
	/**
	 * Tracks if cursor is on the left side or right side of the screen.
	 */
	public var cursorOnLeft(default, null):Bool;
	
	/**
	 * Tracks if cursor is in the top half or bottom half of the screen.
	 */
	public var cursorOnTop(default, null):Bool;
	
	/**
	 * Initializer.
	 * 
	 * @param	parent	Object responsible for creating this manager.
	 */
	public function new(parent:MissionState) 
	{
		parentState = parent;
		mapCursor = parentState.mapCursor;
		mapCursor.subject.addObserver(this);
		
		updateCursorSide();
	}
	
	
	///////////////////////////////////////
	//        INTERNAL  FUNCTIONS        //
	///////////////////////////////////////
	
	/**
	 * Updates cursorOnLeft & cursorOnTop variables based on cursor position.
	 */
	private function updateCursorSide():Void
	{
		cursorOnLeft = mapCursor.col * parentState.tileSize - FlxG.camera.scroll.x < 
			FlxG.width / 2;
		cursorOnTop = mapCursor.row * parentState.tileSize - FlxG.camera.scroll.y < 
			FlxG.height / 2;
	}
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Publicly accessible method for activating the map cursor.
	 * 
	 * Makes the map cursor visible, active, get updated by the MissionState, and
	 * 	react normally to input.
	 */
	public function activateMapCursor():Void
	{
		mapCursor.activate();
		mapCursor.reveal();
		mapCursor.changeInputModes(InputModes.FREE_MOVEMENT);
		parentState.changeCurrUpdatingObj(mapCursor);
	}
	
	/**
	 * Publicly accessible method for deactivating the menuCursor.
	 * 
	 * Deactivates and hides the MapCursor and disables its input.
	 */
	public function deactivateMapCursor():Void
	{
		mapCursor.deactivate();
		mapCursor.hide();
		mapCursor.changeInputModes(InputModes.DISABLED);
	}
	
	/**
	 * Function to satisfy the Observer interface.
	 * Is used to respond to events sent out by the MapCursor, and shouldn't
	 * 	recieve any notifications from anything else.
	 * 
	 * @param 	event		InputEvent object containing information about event type and sender.
	 * @param	notifier	Reference to the object that caused the notification.
	 */
	public function onNotify(event:InputEvent, notifier:Observed):Void
	{
		if (event.getID() != mapCursor.subject.ID)
		{
			trace("ERROR: MapCursorManager recieved a notification from an object other than " +
				"mapCursor.");
		}
		else
		{
			trace("MapCursorManager recieved an event with id", event.getID(), 
				"and type", event.getType());
			
			if (event.getType() == EventTypes.CONFIRM)
			{
				
			}
			else if (event.getType() == EventTypes.CANCEL)
			{
				// Doesn't do anything right now.
			}
			else if (event.getType() == EventTypes.MOVE)
			{	
				updateCursorSide();
				
				var terrainStr:String = "";
				// Get type of terrain tile is at the cursor's position.
				var terrainType:Int = parentState.terrainArray[mapCursor.row][mapCursor.col];
				
				switch(terrainType)
				{
					case TerrainTypes.PLAINS:
						terrainStr = "plains";
					case TerrainTypes.FOREST:
						terrainStr = "forest";
					case TerrainTypes.RUBBLE:
						terrainStr = "rubble";
					default:
						terrainStr = "mysterious";
				}
				
				trace("MapCursor is now over a " + terrainStr + " tile.");
			}
		}
	}
	
}