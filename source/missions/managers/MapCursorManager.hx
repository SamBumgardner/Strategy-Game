package missions.managers;

import cursors.MapCursor;
import flixel.FlxG;
import observerPattern.Observed;
import observerPattern.Observer;
import observerPattern.eventSystem.EventTypes;
import observerPattern.eventSystem.InputEvent;
import units.MapCursorUnitTypes;
import units.MoveID;
import units.Unit;

using observerPattern.eventSystem.EventExtender;
using units.MoveIDExtender;

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
	 * Tracks the cursor's current position.
	 * Updated after each detected move event.
	 */
	public var currCursorPos(default, null):MoveID;
	 
	/**
	 * Remembers the cursor's position before its most recent move.
	 * Updated after each detected move event.
	 */
	public var prevCursorPos(default, null):MoveID;
	
	/**
	 * Tracks mapCursor's current input mode even when cursor is deactivated.
	 * Used to return mapCursor to the proper state when reactivated.
	 */
	public var cursorState:Int;
	
	/**
	 * Tracks if cursor is on the left side or right side of the screen.
	 */
	public var cursorOnLeft(default, null):Bool;
	
	/**
	 * Tracks if cursor is in the top half or bottom half of the screen.
	 */
	public var cursorOnTop(default, null):Bool;
	
	/**
	 * Tracks what kind of unit the mapCursor is currently hovered over.
	 * Should be updated whenever the mapCursor moves.
	 */
	public var hoveredUnitType:MapCursorUnitTypes = NONE;
	
	/**
	 * The Unit object that is currently selected by the mapCursor.
	 * If no unit is selected, should be null.
	 */
	private var selectedUnit:Unit = null;
	
	
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
		
		currCursorPos = MoveIDExtender.newMoveID(mapCursor.row, mapCursor.col);
		
		cursorState = mapCursor.currInputMode;
		
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
	
	/**
	 * Determines if the mapCursor has begun hovering over a unit or not after
	 * 	its most recently notified move event.
	 * If the mapCursor leaves a player-controled unit, it should return to its bouncing 
	 * 	movemode, but if it enters a player-controlled unit's space, it should change to
	 * 	its expanded still moveMode.
	 * Uses the MissionState function isMapCursorOverUnit() to identify what the mapCursor 
	 * 	is over, since this manager doesn't have the necessary info to determine that.
	 * 
	 * Called inside onNotify().
	 */
	private function updateHoveredUnitType():Void
	{
		if (mapCursor.currInputMode == InputModes.FREE_MOVEMENT)
		{
			if (hoveredUnitType == PLAYER_ACTIVE)
			{
				mapCursor.changeMovementModes(MoveModes.BOUNCE_IN_OUT);
			}
		}
		
		hoveredUnitType = parentState.isMapCursorOverUnit();
		
		if (mapCursor.currInputMode == InputModes.FREE_MOVEMENT)
		{
			if (hoveredUnitType == PLAYER_ACTIVE)
			{
				mapCursor.changeMovementModes(MoveModes.EXPANDED_STILL);
			}
		}
	}
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Publicly accessible method for activating the map cursor.
	 * 
	 * Makes the map cursor visible, active, get updated by the MissionState, and
	 * 	return to whatever input mode the cursor had before being deactivated.
	 */
	public function activateMapCursor():Void
	{
		mapCursor.activate();
		mapCursor.reveal();
		
		mapCursor.changeInputModes(cursorState);
		
		updateHoveredUnitType();
		
		parentState.changeCurrUpdatingObj(mapCursor);
	}
	
	/**
	 * Publicly accessible method for deactivating the menuCursor.
	 * 
	 * Deactivates and hides the MapCursor and disables its input.
	 * Also stores the cursor's old input mode so it may be reapplied later. 
	 */
	public function deactivateMapCursor():Void
	{
		mapCursor.deactivate();
		mapCursor.hide();
		
		if (mapCursor.currInputMode != InputModes.DISABLED)
		{
			cursorState = mapCursor.currInputMode;
		}
		
		mapCursor.changeInputModes(InputModes.DISABLED);
	}
	
	/**
	 * Changes the mapCursor's inputState and other variables to reflect the change
	 * 	in state that accompanies a unit becoming selected.
	 */
	public function unitSelected(unit:Unit):Void
	{
		if (unit.team == TeamType.PLAYER)
		{
			mapCursor.changeInputModes(InputModes.PLAYER_UNIT);
		}
		else
		{
			mapCursor.changeInputModes(InputModes.OTHER_UNIT);
		}
		selectedUnit = unit;
		
		mapCursor.changeMovementModes(MoveModes.BOUNCE_IN_OUT);
		
		mapCursor.selectedLocations = unit.moveTiles;
	}
	
	/**
	 * Changes the mapCursor's inputState and other variables to reflect the change
	 * 	in state that accompanies a unit becoming unselected.
	 */
	public function unitUnselected():Void
	{
		mapCursor.changeInputModes(InputModes.FREE_MOVEMENT);
		
		if (selectedUnit.team == TeamType.PLAYER)
		{
			jumpToUnit(selectedUnit);
		}
		else
		{
			updateHoveredUnitType();
		}
		
		selectedUnit = null;
		mapCursor.selectedLocations = null;
	}
	
	/**
	 * Jumps the mapCursor's logical and visible position to the specified unit.
	 * 
	 * @param	unit	The unit the mapCursor should jump to.
	 */
	public function jumpToUnit(unit:Unit):Void
	{
		mapCursor.jumpToPosition(unit.mapRow, unit.mapCol);
	}
	
	/**
	 * Function to satisfy the Observer interface.
	 * Is used to respond to events sent out by the MapCursor, and shouldn't
	 * 	recieve any notifications from anything else.
	 * 
	 * If the cursor is in FREE_MOVEMENT input mode, it should update its hovered unit 
	 * 	type after moving. It shouldn't when used in any other input mode, because hovering
	 * 	over a unit only matters when the player hasn't already selected something to do yet.
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
			if (event.getType() == EventTypes.CONFIRM)
			{
				parentState.mapCursorConfirm();
			}
			
			else if (event.getType() == EventTypes.CANCEL)
			{
				parentState.mapCursorCancel();
			}
			
			else if (event.getType() == EventTypes.MOVE)
			{	
				prevCursorPos = currCursorPos;
				currCursorPos = MoveIDExtender.newMoveID(mapCursor.row, mapCursor.col);
				
				updateCursorSide();
				
				updateHoveredUnitType();
				
				// If a player unit is curently selected...
				if (parentState.controlState == PlayerControlStates.PLAYER_UNIT)
				{
					parentState.calculateNewMoveArrow();
				}
				
				// Get type of terrain tile is at the cursor's position.
				var terrainType:Int = parentState.terrainArray[mapCursor.row][mapCursor.col];
			}
		}
	}
	
}