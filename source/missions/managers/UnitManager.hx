package missions.managers;

import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import missions.MissionState;
import observerPattern.Observed;
import observerPattern.Observer;
import observerPattern.eventSystem.InputEvent;
import observerPattern.eventSystem.UnitEvents;
import units.movement.ArrowTile;
import units.movement.MoveID;
import units.movement.PossibleMove;
import units.RangeTile;
import units.movement.TileChange;
import units.Unit;
import units.UnitInfo;

using units.movement.MoveIDExtender;
using observerPattern.eventSystem.EventExtender;

/**
 * A component of MissionState that acts as a middleman between MissionState 
 * 	and all Unit objects to reduce the complexity of MissionState's code.
 * 
 * Is responsible for the following tasks:
 * 	- Creating and placing Unit objects into the game.
 * 	- Tracking the positions of all Unit objects.
 * 	- Calculating the movement & attack ranges of all Unit objects.
 * 		- Performing initial calculations
 * 		- Tracking movements across the map so movement/attack ranges can be 
 * 			partially recalculated as necessary.
 * 	- Displaying the movement & attack range of a selected unit.
 * 	- Calculating the movement path of a selected unit based on the movements
 * 		of the MapCursor.
 *  - Displaying & updating the movement path of the selected unit.
 * 
 * For more details about the implementation of these features, see the 
 * 	documentation on the functions below.
 * 
 * @author Samuel Bumgardner
 */
class UnitManager implements Observer
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * The MissionState object that created this manager.
	 * Used to access information about the current mission and to call
	 * 	functions as needed to cause changes on the overall MissionState.
	 */
	public var parentState(default, null):MissionState;
	
	/**
	 * Contains all Unit objects present in the current MissionState.
	 */
	public var unitArray(default, null):Array<Unit>;
	
	/**
	 * 2-D array of integers that tracks the positions of all Unit objects
	 * 	in the game world. Each row/col index represents a particular tile,
	 * 	and the value contained within is the ID of the unit at that location.
	 * 
	 * The ID of the unit also corresponds to their index in the unitArray,
	 * 	so it's pretty easy to look up the info of a unit by looking up a location.
	 */
	public var unitMap(default, null):Array<Array<Int>>;
	
	/**
	 * 2-D array of integers that contains the movement cost associated with each
	 * 	terrain tile of the game (for normal movement-type units).
	 */
	private var normTerrainMap:Array<Array<Int>>;
	
	/**
	 * Reference to the current unit's terrain map of choice.
	 * Different movement-type units need to use different terrain maps, so this
	 * 	variable tracks which one should be in use for the currently selected unit.
	 */
	private var unitTerrainArr:Array<Array<Int>>;
	
	/**
	 * 2-D array of TeamID values that marks what side of units are occupying 
	 * 	which spaces of the environment.
	 * Useful for determining whether a particular space on the map will block
	 * 	a unit's movement or not, units cannot move through units that belong
	 * 	to a different TeamID.
	 */
	private var teamMap(default, null):Array<Array<TeamID>>;
	
	/**
	 * FlxGroup of RangeTile objects, which is drawn from whenever movement/
	 * 	attack ranges need to be displayed.
	 */
	private var rangeTilePool:FlxGroup;
	
	/**
	 * FlxGroup of the Unit objects that are in the current mission.
	 * Is needed to help organize the contents of the totalFlxGroup, so 
	 * there isn't just an arbitrary jumble of Flx-inheriting objects mashed inside.
	 */
	public var unitFlxGrp:FlxGroup = new FlxGroup();
	
	/**
	 * FlxGroup of ArrowTile objects, which is drawn from whenever a unit's path of
	 * 	movement needs to be displayed.
	 */
	private var arrowTilePool:FlxGroup;
	
	/**
	 * Array that contains the ArrowTile objects that are currently part of the displayed
	 * 	movement path. 
	 * An array was used because we need to keep track of the order of ArrowTiles objects.
	 */
	private var movePath:Array<ArrowTile> = new Array<ArrowTile>();
	
	/**
	 * Array that contains a series of NeighborDirections that describe the path between
	 * 	a unit and a valid destination. 
	 * 
	 * Used to determine how a unit should move when a movePath has not been constructed
	 * 	for the unit to follow. i.e. non-player controlled units.
	 */
	private var neighborPath:Array<NeighborDirections> = null;
	
	/**
	 * Tracks which index of the movePath/neighborPath the currently moving unit is moving
	 * 	through.
	 * 
	 * -1 acts as the default "not currently moving" index.
	 */
	private var unitMovementIndex:Int = -1;
	
	/**
	 * Number of frames it takes for a unit to move across a single tile.
	 */
	private var framesPerMove(default, never):Int = 6;
	
	/**
	 * Frames remaining in the unit's current move.
	 */
	private var framesLeftInMove:Int = 0;
	
	/**
	 * The distance remaining in the unit's current move (in pixels).
	 */
	private var remainingMoveDist:Float = 0;
	
	/**
	 * Describes the current direction of unit movement.
	 * Used a string instead of the NeighborDirections enum because I'm already getting the 
	 * 	string representation of direction to set the unit's animation, so I might as well
	 * 	use the same value.
	 */
	private var currMoveDir:String = null;
	
	/**
	 * Reference to the function used in the current unit movement.
	 * Should either be pickMoveViaMovePath() or pickMoveViaNeighborPath().
	 * Called inside update().
	 */
	private var currMoveFunction:Void->Bool;
	
	/**
	 * The total cost of the currently displayed movement path. 
	 * Is used to determine whether the drawn movement path should continue to follow the
	 * 	path the user has drawn out with the map cursor, or if it should recalculate the
	 * 	total path so the cost of the drawn path doesn't exceed the selected unit's max
	 * 	movement.
	 */
	private var totalPathCost:Int = 0;
	
	
	
	/**
	 * Publicly-accessible FlxGroup that contains all Flx-inheriting objects under the
	 * 	UnitManager's supervision. Used by MissionState to add all unit-related objects
	 * 	to the scene in one easy call to add().
	 */
	public var totalFlxGrp(default, null):FlxGroup;
	
	/**
	 * Reference to the unit that the MissionState's MapCursor is currently hovering over.
	 */
	public var hoveredUnit:Unit = null;
	
	/**
	 * Reference to the unit that the MissionState's currently selected unit when in the
	 * 	PLAYER_UNIT and OTHER_UNIT states.
	 */
	public var selectedUnit:Unit = null;
	
	/**
	 * Reference to the unit that is the target of the selected unit's current action.
	 */
	public var targetUnit:Unit = null;
	
	/**
	 * Tracks the frame of the idle animation that all idling units should be on.
	 * Should be updated with every update cycle.
	 * Is used whenever a unit is instructed to start up it's idle animation again.
	 */
	public var globalIdleFrame(default, null):Int = 0;
	
	/**
	 * Tracks all changes to tiles across the map.
	 * This includes tiles opening and being blocked by units of all team affiliations.
	 * Whenever a unit needs to recalculate its movement and attack range, it iterates
	 * 	through this array so that each tile change necessary is properly applied.
	 */
	private var tileChanges:Array<TileChange> = new Array<TileChange>();
	
	/**
	 * Maps a unit's ID (which should be used to index the array) to an integer that
	 * 	indicates the last index of tileChanges that this unit has processed.
	 * 
	 * Used when recalculating attack and movement ranges.
	 */
	private var unitHasProcessedArr:Array<Int> = new Array<Int>();
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Intializer.
	 * @param	parent	The MissionState object that presides over this UnitManager.
	 */
	public function new(parent:MissionState) 
	{
		parentState = parent;
		
		unitArray = new Array<Unit>();
		initUnitMap();
		initTerrainMaps();
		initTeamMap();
		initRangeTilePool();
		initArrowTilePool();
		fillTotalFlxGrp();
		
		//temp code, since unitInfo class isn't written yet.
		var dummyUnitInfo:UnitInfo = new UnitInfo();
		
		addUnitToMission(0, 0, dummyUnitInfo, TeamType.ENEMY);
		addUnitToMission(1, 1, dummyUnitInfo, TeamType.ENEMY);
		addUnitToMission(1, 0, dummyUnitInfo, TeamType.PLAYER);
		addUnitToMission(2, 1, dummyUnitInfo, TeamType.PLAYER);
		addUnitToMission(4, 4, dummyUnitInfo, TeamType.PLAYER);
	}
	
	/**
	 * Initializes the unitMap 2-D array.
	 */
	public function initUnitMap():Void
	{
		unitMap = new Array<Array<Int>>();
		for (i in 0...parentState.terrainArray.length)
		{
			unitMap.push(new Array<Int>());
			for (tile in parentState.terrainArray[i])
			{
				unitMap[i].push( -1);
			}
		}
	}
	
	/**
	 * Initializes the terrain maps needed by each of the different movement types.
	 * The code present right now is a placeholder. I'll replace it with the proper 
	 * 	system when movement types are determined and terrain as a whole is more
	 * 	completely planned out.
	 */
	public function initTerrainMaps():Void
	{
		normTerrainMap = new Array<Array<Int>>();
		for (i in 0...parentState.terrainArray.length)
		{
			normTerrainMap.push(new Array<Int>());
			for (tile in parentState.terrainArray[i])
			{
				var moveCost = 1;
				
				if (tile == TerrainTypes.PLAINS)
				{
					moveCost = 1;
				}
				else if (tile == TerrainTypes.FOREST)
				{
					moveCost = 2;
				}
				else if (tile == TerrainTypes.RUBBLE)
				{
					moveCost = 3;
				}
				
				normTerrainMap[i].push(moveCost);
			}
		}
	}
	
	/**
	 * Initializes the teamMap 2-D array.
	 */
	public function initTeamMap():Void
	{
		teamMap = new Array<Array<TeamID>>();
		for (i in 0...parentState.terrainArray.length)
		{
			teamMap.push(new Array<TeamID>());
			for (tile in parentState.terrainArray[i])
			{
				teamMap[i].push(TeamID.NONE);
			}
		}
	}
	
	/**
	 * Initializes the rangeTilePool FlxGroup.
	 * The startingTileCount variable may be adjusted if a different number of tiles
	 * 	is expected to be necessary in most situations.
	 */
	public function initRangeTilePool():Void
	{
		rangeTilePool = new FlxGroup();
		
		var startingTileCount:Int = 100;
		for (i in 0...startingTileCount)
		{
			var rangeTile = new RangeTile();
			rangeTile.kill();
			rangeTilePool.add(rangeTile);
		}
	}
	
	/**
	 * Initializes the arrowTilePool FlxGroup.
	 * The expectedMaxMove variable may be adjusted if it is possible for a unit to
	 * 	move further than 8 tiles in a single move action.
	 */
	private function initArrowTilePool():Void
	{
		arrowTilePool = new FlxGroup();
		
		var expectedMaxMove:Int = 8;
		for (i in 0...expectedMaxMove)
		{
			var arrowTile = new ArrowTile();
			arrowTile.kill();
			arrowTilePool.add(arrowTile);
		}
	}
	
	/**
	 * Adds all objects to the totalFlxGrp in the correct order.
	 */
	private function fillTotalFlxGrp():Void
	{
		totalFlxGrp = new FlxGroup();
		totalFlxGrp.add(rangeTilePool);
		totalFlxGrp.add(unitFlxGrp);
		totalFlxGrp.add(arrowTilePool);
	}
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Instatiates a unit from the provided information and adds it to the mission.
	 * 
	 * @param	row			The starting row position of the newly created Unit.
	 * @param	col			The starting column position of the newly created Unit.
	 * @param	unitInfo	The unitInfo object needed to instatiate the unit.
	 * @param	team		The TeamType of the newly created unit.
	 * @return	The newly added Unit.
	 */
	public function addUnitToMission(row:Int, col:Int, unitInfo:UnitInfo, team:TeamType):Unit
	{
		var newUnit:Unit;
		// Temporary code, can't actually use unitInfo yet.
		newUnit = new Unit(row, col, AssetPaths.eldon_sheet__png, unitArray.length, team, "Eldon");
		
		newUnit.subject.addObserver(this);
		
		unitFlxGrp.add(newUnit);
		unitArray.push(newUnit);
		unitHasProcessedArr.push(tileChanges.length);
		
		unitMap[row][col] = newUnit.subject.ID;
		teamMap[row][col] = newUnit.teamID;
		
		var unitMoveID:MoveID = MoveIDExtender.newMoveID(row, col);
		
		tileChanges.push(new TileChange(unitMoveID, false, newUnit.teamID));
		
		// TEMP CODE: Remove later
		unitTerrainArr = normTerrainMap;
		findMoveAndAttackRange(newUnit);
		
		return newUnit;
	}
	
	public function removeUnitFromMission(unit:Unit):Void
	{
		unitFlxGrp.remove(unit);
		unitHasProcessedArr[unit.subject.ID] = -1;
		unitArray[unit.subject.ID] = null;
		unitMap[unit.preMoveMapPos.getRow()][unit.preMoveMapPos.getCol()] = -1;
		teamMap[unit.preMoveMapPos.getRow()][unit.preMoveMapPos.getCol()] = TeamID.NONE;
		tileChanges.push(new TileChange(unit.preMoveMapPos, true, unit.teamID));
		
		trace("Unit Died...");
	}
	
	/**
	 * Given a row and a column location, this function finds and returns
	 * 	the Unit object that is currently there.
	 * 
	 * @param	row	The row of the game map that should be checked.
	 * @param	col	The column of the game map that should be checked.
	 * @return	The Unit object at that location, or null if no Unit could be found.
	 */
	public function getUnitAtLoc(row:Int, col:Int):Unit
	{	
		var unitID:Int = unitMap[row][col];
		var foundUnit:Unit = null;
		if (unitID != -1)
		{
			foundUnit = unitArray[unitID];
		}
		return foundUnit;
	}
	
	/**
	 * Switches the hoveredUnit variable to reference the passed-in unit.
	 * In the process, the old hovered-over unit is changed back to its idle animation and
	 * 	the new hoverd unit switches to its hover animation.
	 * 
	 * @param	newHoveredUnit	The newly hovered-over unit, or null if there shouldn't be one.
	 */
	public function changeHoveredUnit(newHoveredUnit:Unit):Void
	{
		if (parentState.controlState == PlayerControlStates.FREE_MOVE && hoveredUnit != null &&
			hoveredUnit.team == TeamType.PLAYER && hoveredUnit.canAct)
		{
			hoveredUnit.animation.play("idle", false, false, globalIdleFrame);
		}
		
		hoveredUnit = newHoveredUnit;
		
		if (parentState.controlState == PlayerControlStates.FREE_MOVE && hoveredUnit != null && 
			hoveredUnit.team == TeamType.PLAYER && hoveredUnit.canAct)
		{
			hoveredUnit.animation.play("hover", true);
		}
	}
	
	/**
	 * Runs the necessary setup processes whenever a unit is selected. This includes:
	 * 	- Changing the unitTerrainArray to match the unit's movement type.
	 * 	- Recalculating & displaying the movement and attack range of the unit.
	 * 	- Changing the selectedUnit variable.
	 * 	- Changing the animation of the selected unit (if it is player-controlled).
	 * 
	 * @param	unit	The newly-selected unit.
	 */
	public function unitSelected(unit:Unit):Void
	{
		// Set up unitTerrainArr to match the unit's movement type's terrain array.
		unitTerrainArr = normTerrainMap;
		
		recalcMoveAndAttack(unit);
		displayUnitMoveAttackRange(unit);
		
		selectedUnit = unit;
		
		if (unit.team == TeamType.PLAYER  && unit.canAct)
		{
			// May instead use a variable from the unit to determine what direction to play.
			unit.animation.play("down");
		}
	}
	
	/**
	 * Runs the necessary cleanup processes whenever a unit is unselected. This includes:
	 * 	- Hiding all movement and attack range tiles.
	 * 	- Hiding all ArrowTiles (and cleaning up related variables).
	 * 	- Changing the old selectedUnit's animation back to "idle".
	 * 	- Clearing selectedUnit and unitTerrainArr variables.
	 */
	public function unitUnselected():Void
	{
		hideAllRangeTiles();
		hideAllArrowTiles();
		clearMovePath();
		selectedUnit.animation.play("idle", false, false, globalIdleFrame);
		selectedUnit = null;
		unitTerrainArr = null;
	}
	
	/**
	 * Updates a unit's logical (not visual) position on the map to the specified
	 * 	row and column location.
	 * 
	 * Depends on a unit already existing on the map.
	 * May need rewriting later to handle units getting
	 * dropped after being rescued.
	 * 
	 * @param	unit	The unit whose logical variables should be changed.
	 * @param	row 	The row location of the unit's new logical position.
	 * @param	col 	The col location of the unit's new logical position.
	 */
	public function updateUnitPos(unit:Unit, row:Int, col:Int):Void
	{
		var oldMoveID:MoveID = MoveIDExtender.newMoveID(unit.mapPos.getRow(), unit.mapPos.getCol());
		var newMoveID:MoveID = MoveIDExtender.newMoveID(row, col);
		
		unitMap[unit.mapPos.getRow()][unit.mapPos.getCol()] = -1;
		teamMap[unit.mapPos.getRow()][unit.mapPos.getCol()] = TeamID.NONE;
		tileChanges.push(new TileChange(oldMoveID, true, unit.teamID));
		
		unitMap[row][col] = unit.subject.ID;
		teamMap[row][col] = unit.teamID;
		tileChanges.push(new TileChange(newMoveID, false, unit.teamID));
		
		unit.mapPos = newMoveID;
		
		// TEMP CODE: Remove later
		unitTerrainArr = normTerrainMap;
		findMoveAndAttackRange(unit);
	}
	
	/**
	 * Begins movement for the selected unit.
	 * 
	 * It handles the first half of updating the unit's logical position and
	 * 	sets up the necessary variables so the unit can begin updating its
	 * 	visual position as well.
	 * 
	 * @param	row	The row location that the selected unit should move to.
	 * @param	col	The col location that the selected unit should move to.
	 */
	public function initiateUnitMovement(row:Int, col:Int):Void
	{
		// Adjust unit's logical position.
		var newMoveID:MoveID = MoveIDExtender.newMoveID(row, col);
		
		unitMap[selectedUnit.mapPos.getRow()][selectedUnit.mapPos.getCol()] = -1;
		teamMap[selectedUnit.mapPos.getRow()][selectedUnit.mapPos.getCol()] = TeamID.NONE;
		
		unitMap[row][col] = selectedUnit.subject.ID;
		teamMap[row][col] = selectedUnit.teamID;
		
		selectedUnit.mapPos = newMoveID;
		
		// Begin changing unit's visual position.
		if (movePath.length != 0 || neighborPath == null)
		{
			hideAllRangeTiles();
			hideAllArrowTiles();
			currMoveFunction = pickMoveViaMovePath;
		}
		else
		{
			currMoveFunction = pickMoveViaNeighborPath;
		}
	}
	
	/**
	 * Finalizes the selected unit's logical movement, completing the changes that
	 * 	begain in initiateUnitMovement().
	 */
	public function confirmUnitMove():Void
	{
		var oldMoveID:MoveID = selectedUnit.preMoveMapPos;
		var newMoveID:MoveID = selectedUnit.mapPos;
		
		tileChanges.push(new TileChange(oldMoveID, true, selectedUnit.teamID));
		
		tileChanges.push(new TileChange(newMoveID, false, selectedUnit.teamID));
		
		selectedUnit.preMoveMapPos = selectedUnit.mapPos;
		
		// TEMP CODE: Remove later
		unitTerrainArr = normTerrainMap;
		findMoveAndAttackRange(selectedUnit);
	}
	
	/**
	 * Resets the selected unit's x & y values and logical position variables to match its 
	 *  old row/col position. Also changes its animation back to "down".
	 * 
	 * Used to cancel a unit's movement and let the player go back to deciding a different
	 * 	destination for the unit.
	 * 
	 * Won't be used for non-player controlled units.
	 */
	public function undoUnitMove():Void
	{
		// Change unit & team maps back to the unit's old position.
		unitMap[selectedUnit.mapPos.getRow()][selectedUnit.mapPos.getCol()] = -1;
		teamMap[selectedUnit.mapPos.getRow()][selectedUnit.mapPos.getCol()] = TeamID.NONE;
		
		unitMap[selectedUnit.preMoveMapPos.getRow()][selectedUnit.preMoveMapPos.getCol()] = 
			selectedUnit.subject.ID;
		teamMap[selectedUnit.preMoveMapPos.getRow()][selectedUnit.preMoveMapPos.getCol()] = 
			selectedUnit.teamID;
		
		// Set the unit's mapPos back to its old value
		selectedUnit.mapPos = selectedUnit.preMoveMapPos;
		
		// Jump the unit sprite back to its old position.
		selectedUnit.x = selectedUnit.mapPos.getCol() * parentState.tileSize;
		selectedUnit.y = selectedUnit.mapPos.getRow() * parentState.tileSize;
		
		// Or play whatever default move direction the character should use.
		selectedUnit.animation.play("down");
	}
	
	/**
	 * Identifies the group of units within "range" of the current selected unit that
	 * 	pass the provided test function. Will often be used by target-type menus to 
	 * 	identify the set of targets they can look at.
	 * 
	 * @param	rangesToCheck	An array of neighbor distances to check. [1] means only check
	 * 							1-distance away neighbors, [1,2] means check both 1- and 
	 * 							2-distance away neighbors, etc.
	 * @param	testFunc     	A function that returns true if the neighbor Unit should be 
	 * 							included in the returned array of valid Units. The first
	 *                       	argument should be for the currently selected unit, and
	 *       	             	the second argument should be for the neighbor to be checked.
	 * 
	 * @return	An array containing all valid Unit objects within range.
	 */
	public function getValidUnitsInRange(rangesToCheck:Array<Int>, 
		testFunc:Unit->Unit->Bool):Array<Unit>
	{
		var validUnits:Array<Unit> = new Array<Unit>();
		for (range in rangesToCheck)
		{
			for (colOffset in -range...(range+1))
			{
				for (rowModifier in [-1, 1])
				{
					var rowOffset:Int = cast (range - Math.abs(colOffset)) * rowModifier;
					
					var startTile = selectedUnit.mapPos;
					
					var neighborLoc:MoveID = startTile.getOtherByOffset(rowOffset, colOffset);
					
					// If the neighbor location is in the map...
					if (neighborLoc != -1)
					{
						// Look up the id of the unit at neighbor location.
						var neighborUnitID:Int = unitMap[neighborLoc.getRow()]
							[neighborLoc.getCol()];
						
						// If the neighboring tile does contain a unit...
						if (neighborUnitID != -1) 
						{
							var neighborUnit:Unit = unitArray[neighborUnitID];
							
							// Check if the found unit passes the provided test.
							if (testFunc(selectedUnit, neighborUnit))
							{
								validUnits.push(neighborUnit);
							}
						}
					}
					
					// Prevent checking the same square twice when rowOffset is 0.
					if (rowOffset == 0)
					{
						break;
					}
				}
			}
		}
		
		return validUnits;
	}
	
	/**
	 * Function to satisfy the Observer interface.
	 * Recieves & responds to notifications from Unit-type objects.
	 * 
	 * This will likely consist of level-up events, units being defeated, etc.
	 * 
	 * Will be implemented at a later date, when the Unit class is more developed.
	 * 
	 * @param	event		Contains information about what sort of event ocurred.
	 * @param	notifier	The object that detected the event and sent the notification.
	 */
	public function onNotify(event:InputEvent, notifier:Observed):Void 
	{
		var notifyingUnit:Unit = cast notifier;
		trace("UnitManager's onNotify was called");
		if (event.getType() == UnitEvents.DIED)
		{
			removeUnitFromMission(notifyingUnit);
		}
	}
	
	
	///////////////////////////////////////
	//      MISC. HELPER FUNCTIONS       //
	///////////////////////////////////////
	
	/**
	 * Takes a unit and a moveID and looks up the corresponding PossibleMove
	 * 	from that unit's MoveTiles.
	 * 
	 * @param	unit	The unit whose moveTiles should be used for lookup.
	 * @param	moveID	The moveID of the tile to look up.
	 * @return	The PossibleMove from the unit's MoveTiles.
	 */
	private function convertIDsToMoves(unit:Unit, moveID:MoveID):PossibleMove
	{
		return unit.moveTiles.get(moveID);
	}
	
	///////////////////////////////////////
	//  MOVEMENT AND ATTACK RANGE FUNC.  //
	///////////////////////////////////////
	
		///////////////////////
		// GENERAL FUNCTIONS //
		///////////////////////
	
	/**
	 * Displays rangeTiles to show the unit's movement and attack ranges. 
	 * 
	 * I feel like this is inefficient at the moment. There should be some way to run 
	 * 	through the lists simultaneously to cut out wasted checks.
	 * 
	 * @param	unit	The Unit whose movement/attack range is used when displaying RangeTiles.
	 */
	private function displayUnitMoveAttackRange(unit:Unit):Void
	{
		if (unit.rangesHaveChanged)
		{
			var moveTilesArray:Array<MoveID> = new Array<MoveID>();
			for (key in unit.moveTiles.keys())
			{
				moveTilesArray.push(key);
			}
			
			calculateAttackTiles(unit, moveTilesArray);
			
			unit.rangesHaveChanged = false;
		}
		
		// Display all movement range (blue) RangeTiles.
		for (moveID in unit.moveTiles.keys())
		{
			var rangeTile:RangeTile = cast rangeTilePool.recycle(RangeTile);
			rangeTile.moveMode = true;
			rangeTile.setPosition(moveID.getCol() * parentState.tileSize, moveID.getRow() *
				parentState.tileSize);
		}
		
		// Display all attack range (red) RangeTiles.
		for (moveID in unit.attackTiles.keys())
		{
			// But only if there isn't already a movement range tile at that location.
			if (!unit.moveTiles.exists(moveID))
			{
				var rangeTile:RangeTile = cast rangeTilePool.recycle(RangeTile);
				rangeTile.moveMode = false;
				rangeTile.setPosition(moveID.getCol() * parentState.tileSize, moveID.getRow() *
					parentState.tileSize);
			}
		}
	}
	
	/**
	 * Hides range tiles by killing all currently alive RangeTiles in the rangeTilePool.
	 */
	private function hideAllRangeTiles():Void
	{
		rangeTilePool.forEachAlive(function(rangeTile:FlxBasic){rangeTile.kill(); });
	}
	
	/**
	 * Clears a unit's existing move and attack range information, then calculates the
	 * 	unit's move and attack range based on its current position and the environment
	 * 	and other units around it.
	 * 
	 * Calls bfCalcMoveTiles() to determine the entirety of the unit's move range from its
	 * 	starting space, and then takes the unit's whole set of reachable tiles and uses
	 * 	it to calculate all tiles within the unit's attack range.
	 * 
	 * Is also responsible for updating the unit's entry in the unitHasProcessedArr 
	 * 	so the unit knows that it is up-to-date with the most recent tile opened/closed
	 * 	changes on the map.
	 * 
	 * @param	unit The unit whose move and attack range should be calculated.
	 */
	public function findMoveAndAttackRange(unit:Unit):Void
	{
		unit.moveTiles = null;
		unit.moveTiles = new Map<MoveID, PossibleMove>();
		unit.attackTiles = null;
		unit.attackTiles = new Map<MoveID, Bool>();
		
		var startingTile:PossibleMove = new PossibleMove(START, 0, unit.mapPos.getRow(), unit.mapPos.getCol());
		unit.moveTiles.set(startingTile.moveID, startingTile);
		
		startingTile.numTimesInBfQueue++;
		var movementTiles:Array<MoveID> = bfCalcMoveTiles(unit, [startingTile.moveID]);
		movementTiles.push(startingTile.moveID);
		calculateAttackTiles(unit, movementTiles);
		
		// Update unit's index of unitHasProcessedArr so it shows this unit's move range is 
		// 	up-to-date.
		unitHasProcessedArr[unit.subject.ID] = unitHasProcessedArr.length;
	}
	
	/**
	 * Identifies what tiles were opened and closed by the opposing team since the unit last 
	 * 	caluclated its movement range, then calls move & attack tile recalculation functions
	 * 	with the appropriate parameters.
	 * 
	 * Blocked tiles should be passed into tilesBlockedRecalc(), while opened tiles should
	 * 	be passed into tilesOpenedRecalc().
	 * 
	 * @param	unit	The unit whose move & attack range is being recalculated.
	 */
	public function recalcMoveAndAttack(unit:Unit):Void
	{
		// Use unit's id to find out what index they need to recalculate from.
		var startIndex = unitHasProcessedArr[unit.subject.ID];
		
		if (startIndex != tileChanges.length)
		{
			var tilesOpened:Map<MoveID, Bool> = new Map<MoveID, Bool>();
			var tilesBlocked:Map<MoveID, Bool> = new Map<MoveID, Bool>();
			
			for (i in startIndex...tileChanges.length)
			{
				var tileChange:TileChange = tileChanges[i];
				// If the change was a blocking move, then it should only be considered if the
				// 	move happened within this unit's moveTiles area. Regardless, only consider
				//	moves done by a non-friendly unit (which can block movement)
				if ((tileChange.wasOpened || unit.moveTiles.exists(tileChange.moveID)) && 
					unit.teamID != tileChange.causedBy)
				{
					// Push the tile change's move ID into the map that matches what kind of change
					//	it was. Need to remove from opposite map because the new tileChange undid
					//	any opposite tile change that was done before.
					if (tileChange.wasOpened)
					{
						tilesOpened.set(tileChange.moveID, true);
						tilesBlocked.remove(tileChange.moveID);
					}
					else
					{
						tilesBlocked.set(tileChange.moveID, true);
						tilesOpened.remove(tileChange.moveID);
					}
				}
			}
			
			// Update unitHasProcessedArr so it shows this unit move range is up-to-date.
			unitHasProcessedArr[unit.subject.ID] = tileChanges.length;
			
			// Recalculate move range based on blocked tiles.
			var blockedTilesArr:Array<MoveID> = new Array<MoveID>();
			
			for (key in tilesBlocked.keys())
			{
				blockedTilesArr.push(key);
			}
			tilesBlockedRecalc(unit, blockedTilesArr);
			
			// Recalculate move range based on opened tiles.
			var openedTilesArr:Array<MoveID> = new Array<MoveID>();
			for (key in tilesOpened.keys())
			{
				openedTilesArr.push(key);
			}
			tilesOpenedRecalc(unit, openedTilesArr);
		}
	}
	
	/**
	 * Helper function for various movement-range calculating functions. Runs a provided
	 * 	testing function on each of the neighbors of a provided tile, and returns an array
	 * 	of all neighbor tiles that returned "true" when run through the testing function.
	 * 
	 * @param	startTile		The MoveID whose neighbors need to be checked with the testFunc.
	 * @param	rangesToCheck	An array of neighbor distances to check. [1] means only check
	 * 							1-distance away neighbors, [1,2] means check both 1- and 
	 * 							2-distance away neighbors, etc.
	 * @param	testFunc		A function that returns true if the neighbor MoveID should be 
	 * 							included in the returned array of valid neighbors. First argument
	 * 							should be for the startTile MoveID & the second is for the 
	 * 							neighbor MoveID.
	 * @return	An array of all neighboring MoveIDs that passed the provided function's test.
	 */
	private function getValidNeighbors(startTile:MoveID, rangesToCheck:Array<Int>,
		testFunc:MoveID->NeighborDirections->Bool, ?stopAfterValid:Bool = false):Array<MoveID>
	{
		var validNeighbors:Array<MoveID> = new Array<MoveID>();
		for (range in rangesToCheck)
		{
			for (colOffset in -range...(range+1))
			{
				for (rowModifier in [-1, 1])
				{
					var direction:NeighborDirections = NeighborDirections.START;
					var rowOffset:Int = cast (range - Math.abs(colOffset)) * rowModifier;
					var neighborTile:MoveID = -1;
					neighborTile = startTile.getOtherByOffset(rowOffset, colOffset);
					
					if (colOffset == 0)
					{
						if (rowOffset < 0)
							direction = UP;
						else
							direction = DOWN;
					}
					else if (rowOffset == 0)
					{
						if (colOffset < 0)
							direction = LEFT;
						else 
							direction = RIGHT;
					}
					else if (rowOffset < 0)
					{
						if (colOffset < 0)
							direction = UP_LEFT;
						else
							direction = UP_RIGHT;
					}
					else if (rowOffset > 0)
					{
						if (colOffset < 0)
							direction = DOWN_LEFT;
						else
							direction = DOWN_RIGHT;
					}
					
					// If the neighboring tile was outside the map's bounds, it will be null.
					if (neighborTile != -1 && testFunc(neighborTile, direction))
					{
						validNeighbors.push(neighborTile);
						
						// Optionally stop after finding the first valid neighbor.
						if (stopAfterValid)
						{
							return validNeighbors;
						}
					}
					
					// Prevent checking the same square twice when rowOffset is 0.
					if (rowOffset == 0)
					{
						break;
					}
				}
			}
		}
		
		return validNeighbors;
	}
	
	/**
	 * Helper function used by various functions here. Passed as an argument into a call
	 * 	to getValidNeighbors. This functions only criteria is that the neighbor tile is already
	 * 	in the unit's moveTiles map, meaning that it already has a direction & value.
	 * 
	 * @param	unit			The unit whose moveTiles map should be used during testing.
	 * @param	neighborID		The MoveID that is being tested.
	 * @param	dirFromOrigin	Not used in this function. Inc. to match requried param types.
	 * @return	Bool indicating if the provided MoveID was in the unit's moveTiles map.
	 */
	private function tileInMoveTiles(unit:Unit, neighborID:MoveID, 
		dirFromOrigin:NeighborDirections):Bool
	{
		return unit.moveTiles.exists(neighborID);
	}
	
	/**
	 * Calls bfCalcMoveTiles(), passing in all tiles that are both in the unit's movement 
	 * 	range and are adjacent one of the tiles in the "openedTiles" array that is passed into 
	 * 	this function.
	 * 
	 * They'll correctly fill in the cost to reach the newly opened tiles and propogate those 
	 * 	changes across the whole movement range as needed.
	 * 
	 * Also calls calculateAttackTiles() to update the unit's attack range to match.
	 * 
	 * @param	unit		The unit whose movement/attack range is being recalculated.
	 * @param	openedTiles	Array of MoveIDs of newly opened tiles. Used to determine what tiles 
	 * 						should be passed into the call to bfCalcMoveTiles.
	 */
	public function tilesOpenedRecalc(unit:Unit, openedTiles:Array<MoveID>):Void
	{
		var tilesToBfCalcFrom:Array<MoveID> = new Array<MoveID>();
		for (tileID in openedTiles)
		{
			if (!unit.moveTiles.exists(tileID))
			{
				tilesToBfCalcFrom = tilesToBfCalcFrom.concat(
					getValidNeighbors(tileID, [1], tileInMoveTiles.bind(unit)));
			}
		}
		
		for (tile in tilesToBfCalcFrom)
		{
			unit.moveTiles.get(tile).numTimesInBfQueue++;
		}
		
		var addedTiles:Array<MoveID> = bfCalcMoveTiles(unit, tilesToBfCalcFrom);
		calculateAttackTiles(unit, addedTiles);
	}
	
	/**
	 * Helper function for tilesBlockedRecalc(). Passed as an argument into a call
	 * 	to getValidNeighbors. This function's criteria is that the neighbor tile is already
	 * 	in the unit's moveTiles map, and that its move ID isn't in the array of MoveIDs 
	 * 	that represent the directly blocked tiles (both the removed and to-be-removed ones).
	 * 
	 * @param	unit			The unit whose moveTiles map should be used during testing.
	 * @param	directlyBlocked	Array of tiles that were directly blocked during recalculation.
	 * @param	alreadyRemovedIndex	The heighest index of directlyBlocked that has been removed.
	 * @param	neighborID		The MoveID that is being tested.
	 * @param	dirFromOrigin	Not used in this function. Inc. to match requried param types.
	 * @return	Bool indicating if the provided MoveID is valid for tilesBlockedRecalc().
	 */
	private function blockRecalcTest(unit:Unit, directlyBlocked:Array<MoveID>, 
		alreadyRemovedIndex:Int, neighborID:MoveID, dirFromOrigin:NeighborDirections):Bool
	{
		var result:Bool = false;
		if (unit.moveTiles.exists(neighborID))
		{
			result = true;
			
			// Now test if the tile is the unprocessed section of the directlyBlocked array
			for (i in 1...(directlyBlocked.length - alreadyRemovedIndex))
			{
				if (directlyBlocked[directlyBlocked.length - i] == neighborID)
				{
					result = false;
				}
			}
		}
		
		return result;
	}
	
	/**
	 * Removes all directly blocked tiles from the unit's movement range, then calls 
	 * 	tileBlockedRecalcMove(), passing tiles that were adjacent to directly blocked
	 * 	tiles (but not any tiles that were directly blocked).
	 * 
	 * After removing all directly & indirectly blocked movement spaces, the array of
	 * 	all removed tiles is passed in to tileBlockedRecalcAttack() to recalculate the
	 * 	unit's attack range.
	 * 
	 * @param	unit			The unit whose move range is being recalculated.
	 * @param	blockedTiles	Array of blocked tile locations.
	 */
	public function tilesBlockedRecalc(unit:Unit, blockedTiles:Array<MoveID>):Void
	{
		var tilesToBeChecked:Array<MoveID> = new Array<MoveID>();
		for (i in 0...(blockedTiles.length))
		{
			var tileID:MoveID = blockedTiles[i];
			
			if (unit.moveTiles.exists(tileID))
			{
				unit.moveTiles.remove(tileID);
				
				tilesToBeChecked = tilesToBeChecked.concat(
					getValidNeighbors(tileID, [1], blockRecalcTest.bind(unit, blockedTiles, i)));
			}
		}
		
		var removedTiles:Array<MoveID> = tileBlockedRecalcMove(unit, tilesToBeChecked);
		removedTiles = removedTiles.concat(blockedTiles);
		
		tileBlockedRecalcAttack(unit, removedTiles);
	}
	
	/**
	 * Helper function passed as a parameter into getValidNeighbors(). Returns the validity 
	 * 	of the neighbor as normal, but also pushes certain "invalid" neighbors into parameter 
	 * 	arrays. These arrays will be bound to this function before it is passed into 
	 * 	getValidNeighbors(), and as a result will be built up as getValidNeighbors() runs.
	 * 
	 * Because of this, the function effectively sorts the neighbor tiles into 4 different
	 * 	categories, three of which are remembered for later:
	 * 		valid [see below for criteria] (array returned by getValidNeighbors)
	 * 		neighbor came directly from origin (stored in fromOrigin array)
	 * 		neighbor not in unit's moveTiles (stored in notInMoveRange array)
	 * 		invalid (not stored anywhere)
	 * 
	 * I could've built these three arrays by doing three separate calls to getValidNeighbors,
	 * 	each with different criteria for what is "valid" or not, but it seemed wasteful to
	 * 	write a bunch of separate functions and redo the same process when I could just 
	 * 	sort the neighbors into the 4 categories in a single pass.
	 * 
	 * When checking for validity, ensures that the following criteria are met:
	 * 	neighborID is a key for a valid move in the unit's moveTiles map.
	 * 	The PossibleMove obj identified by neighborID does not point directly away from 
	 * 		the origin tile. Checked by ensuring that direction != dirFromOrigin.
	 * 	
	 * NOTE: In a previous version of this function, PossibleMoves with direction START
	 * 	were treated as invalid. That behavior was incorrect; START-Direction tiles are
	 * 	valid neighbors to get move costs & direction from.
	 * 
	 * 	My original reasoning for treating it as invalid was because the START tile should 
	 * 	never be put through the logic within the tileBlockedRecalcMove()'s test, which is
	 * 	a process that all "valid" tiles are supposed to be put through. It turns out that
	 * 	I'd already prevented the START-direction tile from being processed, but I hadn't
	 * 	fixed the logic in this function to treat the START-direction tile as a valid neighbor.
	 * 
	 * @param	unit			The unit whose move range is being recalculated.
	 * @param	fromOrigin		Array of neighbor tiles that point away from the origin tile.
	 * @param	notInMoveRange	Array of neighbor tiles that are not currently within the unit's 
	 * 							moveTiles
	 * @param	neighborID		MoveID of the neighbor tile.
	 * @param	dirFromOrigin	Direction moved between the "origin" tile and the neighbor
	 */
	private function tileBlockedTestFunc(unit:Unit, fromOrigin:Array<PossibleMove>, 
		notInMoveRange:Array<MoveID>, neighborID:MoveID, 
		dirFromOrigin:NeighborDirections):Bool
	{
		var isValid:Bool = false;
		
		var neighborMove:PossibleMove = unit.moveTiles.get(neighborID);
		
		if (neighborMove == null)
		{
			notInMoveRange.push(neighborID);
		}
		else if (neighborMove.direction == dirFromOrigin)
		{
			fromOrigin.push(neighborMove);
		}
		else
		{
			isValid = true;
		}
		
		return isValid;
	}
	
	/**
	 * Identifies changes that should happen to a unit's moveTiles map as a result of tile(s)
	 * 	within their movement range being blocked. 
	 * 
	 * The algorithm's strategy is as follows:
	 * 
	 * If recalculating because spot was closed off, must check all (non-START direction) tiles 
	 * 	adjacent to the closed space. For each of those tiles, do the following:
	 * 		Find lowest-cost adjacent tile that does not point directly away from this tile. 
	 * 			Calculate new self value based on movement from the selected tile as normal.
	 * 			If the new self value is larger than the unit's move range, remove it from the
	 * 				unit's moveTiles map.
	 * 			If self moveCost increased (or tile's could no longer be reached due to distance)
	 * 				then all adjacent tiles that point directly away from this tile need 
	 * 				to be pushed onto the list.
	 * 			If there are any tiles adjacent to this one that are direction NONE and this tile
	 * 				isn't at the movement cap, add this tile to a list of tiles that will be run
	 * 				through the breadth-first calculation.
	 * 		If there is no adjacent tile that does not point directly away from this tile, then
	 * 			set this tile's direction to NONE and add those adjacent tiles to the list of 
	 * 			tiles to be processed.
	 * 
	 * 
	 * @param	unit				The unit whose movement range is being recalculated.
	 * @param	moveIDsToProcess	Array of all tiles that were adjacent to the blocked tiles.
	 */
	public function tileBlockedRecalcMove(unit:Unit, moveIDsToProcess:Array<MoveID>):Array<MoveID>
	{
		// TEMP CODE: need to actually select the correct terrain array based on movement type.
		var terrainCosts:Array<Array<Int>> = normTerrainMap;
		
		var removedTiles:Array<MoveID> = new Array<MoveID>();
		var tilesToBfCalcFrom:Array<MoveID> = new Array<MoveID>();
		var i:Int = 0;
		
		var validTiles:Array<PossibleMove>;
		
		var tilesToProcess:Array<PossibleMove> = moveIDsToProcess.map(convertIDsToMoves.bind(unit));
		
		while (i < tilesToProcess.length)
		{
			// Get the current tile that we're processing.
			var currTile:PossibleMove = tilesToProcess[i];
			
			if (currTile.direction != START && unit.moveTiles.exists(currTile.moveID))
			{
				// Declare empty arrays to be used in the tileBlockedTestFunc() function.
				var pointingDirectlyAway:Array<PossibleMove> = new Array<PossibleMove>();
				var notInMoveRange:Array<MoveID> = new Array<MoveID>();
				
				// Create array for valid tiles, and fill pointing away & not in range tiles.
				validTiles = getValidNeighbors(currTile.moveID, [1], tileBlockedTestFunc.bind(unit, 
					pointingDirectlyAway, notInMoveRange))
						.map(convertIDsToMoves.bind(unit));
				
				// If there was some tile adjacent to this one that was not reached by moving 
				// 	through this tile... (is not pointing directly away)
				if (validTiles.length > 0)
				{
					// Need to find the lowest-cost valid tile.
					// Initially set min variables to match first entry in valid tiles.
					var minNeighborCost:Int = validTiles[0].moveCost;
					var minNeighborDir:NeighborDirections = 
						currTile.moveID.getDirFromOther(validTiles[0].moveID);
					
					// Compare those initial min variables against other tiles in the valid array.
					for (j in 1...validTiles.length)
					{
						if (validTiles[j].moveCost < minNeighborCost)
						{
							minNeighborCost = validTiles[j].moveCost;
							minNeighborDir = currTile.moveID.getDirFromOther(validTiles[j].moveID);
						}
					}
					
					// find the cost currTile will have when reached by moving through min tile.
					var newMoveCost = minNeighborCost + 
						terrainCosts[currTile.moveID.getRow()][currTile.moveID.getCol()];
					
					// set the currTile direction to show it was reached by moving through min tile.
					currTile.direction = minNeighborDir;
					
					if (newMoveCost > currTile.moveCost) // If cost increased...
					{
						// set the currTile moveCost to match the calculated cost from earlier.
						currTile.moveCost = newMoveCost;
						
						// All tiles that were reached through this tile need to go through this
						//	process as well.
						for (tile in pointingDirectlyAway)
						{
							tilesToProcess.push(tile);
						}
						
						// If outside of the unit's max allowed movement, remove entry from map.
						if (currTile.moveCost > unit.move)
						{
							unit.moveTiles.remove(currTile.moveID);
							removedTiles.push(currTile.moveID);
							
							// Remove this tile from tiles to BfCalcFrom, since it's no longer valid.
							tilesToBfCalcFrom.remove(currTile.moveID);
						}
						
					}
					
					// If less than the unit's max allowed movement AND there are adjacent tiles
					// not currently in the movement dictionary, then try using it in bfCalc...
					if (currTile.moveCost < unit.move && notInMoveRange.length > 0)
					{
						tilesToBfCalcFrom.push(currTile.moveID);
						currTile.numTimesInBfQueue++;
					}
				}
				else // There were no adjacent tiles that did not come from this one.
				{
					// Remove this tile from the movement range array.
					unit.moveTiles.remove(currTile.moveID);
					removedTiles.push(currTile.moveID);
					
					// Remove this tile from tiles to BfCalcFrom, since it's no longer valid.
					tilesToBfCalcFrom.remove(currTile.moveID);
					
					// All tiles that came from this need to be processed as well.
					for (tile in pointingDirectlyAway)
					{
						tilesToProcess.push(tile);
					}
				}
			}
			// Increment i for next time through loop.
			i++;
		}
		// Not very efficient way to do set difference. May be better to sort arrays and comapre
		//	in linear time?
		for (tile in bfCalcMoveTiles(unit, tilesToBfCalcFrom))
		{
			removedTiles.remove(tile);
		}
		
		return removedTiles;
	}
	
	/**
	 * Helper function used by bfCalcMoveTiles as its "test function" argument to 
	 * 	getValidNeighbors(). Considers a neighbor tile valid as long as the tile contains
	 * 	an allied unit (or is empty).
	 * 
	 * @param	unit			The unit whose movement range is being calculated.
	 * @param	neighborID		The MoveID of the currently inspected neighbor tile.
	 * @param	dirFromOrigin	The direction between the "origin tile" given to 
	 * 							getValidNeighbors() and the currently checked neighbor tile.
	 * @return	Boolean value indicating whether the neighbor tile should be considered valid.
	 */
	public function bfCalcTestFunc(unit:Unit, neighborID:MoveID, 
		dirFromOrigin:NeighborDirections):Bool
	{
		return teamMap[neighborID.getRow()][neighborID.getCol()] == TeamID.NONE ||
			teamMap[neighborID.getRow()][neighborID.getCol()] == unit.teamID;
	}
	
	
	/**
	 * Performs a breadth-first style traversal of the 2-D terrain array beginning at the unit's
	 * 	current position to find what tiles are within the unit's movement range.
	 * 
	 * Every tile that is valid to move to is added to the unit's moveTiles map and contains
	 * 	data about the location of the tile, the direction of movement used to reach it from
	 * 	the previous tile (when following an optimal path) and the optimal movement cost to 
	 * 	reach this tile.
	 * 
	 * The algorithm's strategy to do this is as follows:
	 * 
	 * 	while (curr_index < len(list_of_tiles_to_check))
	 * 		grab tile at curr_index.
	 * 		decrement tile's numTimesInQueue.
	 * 		If numTimesInQueue == 0: (if it's > 0, then it'll come up again later in the queue)
	 * 			for each adjacent tile...
	 * 				calculate cost to move to other tile (self cost + move to other tile cost)
	 * 				if adj tile direction == NONE or adj tile's moveCost < calculated cost:
	 * 					set adj tile moveCost to calculated cost
	 * 					set adj tile direction to point directly away from this tile
	 * 					add adj tile to list_of_tiles_to_check.
	 * 					increase adj tile's numTimesInQueue by 1.
	 * 		else if numTimesInQueue < 0:
	 * 			Some sort of error occurred. Shouldn't have happened.
	 * 		
	 * 		increment curr_index.
	 * 
	 * @param	unit			The unit whose range is being recalculated.
	 * @param	tilesToProcess	Initial array of tiles for the algorithm's processing queue.
	 * @return	Array of all tiles that were added to the unit's movement range over the 
	 * 			course of the breadth-first traversal.
	 */
	public function bfCalcMoveTiles(unit:Unit, tilesToProcess:Array<MoveID>):Array<MoveID>
	{	
		var i:Int = 0;
		var currTile:PossibleMove;
		
		var addedTiles:Array<MoveID> = new Array<MoveID>();
		
		while (i < tilesToProcess.length)
		{
			currTile = unit.moveTiles.get(tilesToProcess[i]);
			currTile.numTimesInBfQueue--;
			
			if (currTile.numTimesInBfQueue == 0)
			{
				// Bet a list of neighbor tiles reachable by the current unit.
				var validNeighbors:Array<MoveID> = 
					getValidNeighbors(currTile.moveID, [1], bfCalcTestFunc.bind(unit));
				
				for (neighborMoveID in validNeighbors)
				{
					var neighborTile = unit.moveTiles.get(neighborMoveID);
					
					var newNeighborCost = currTile.moveCost + 
						unitTerrainArr[neighborMoveID.getRow()][neighborMoveID.getCol()];
					
					if (newNeighborCost <= unit.move)
					{
						var neighborChanged:Bool = false;
						
						if (neighborTile == null)
						{
							var direction:NeighborDirections = 
								neighborMoveID.getDirFromOther(tilesToProcess[i]);
							
							neighborTile = new PossibleMove(direction, newNeighborCost, 
								neighborMoveID.getRow(), neighborMoveID.getCol());
							
							addedTiles.push(neighborMoveID);
							
							neighborChanged = true;
						}
						else if (neighborTile.moveCost > newNeighborCost)
						{
							var direction:NeighborDirections = 
								neighborMoveID.getDirFromOther(tilesToProcess[i]);
							
							neighborTile.moveCost = newNeighborCost;
							neighborTile.direction = direction;
							
							neighborChanged = true;
						}
						
						if (neighborChanged)
						{
							unit.moveTiles.set(neighborMoveID, neighborTile);
							
							if (neighborTile.moveCost < unit.move)
							{
								neighborTile.numTimesInBfQueue++;
								tilesToProcess.push(neighborMoveID);
							}
						}
					}
				}
			}
			else if (currTile.numTimesInBfQueue < 0)
			{
				trace("ERROR: The following tile is in the queue a negative # of times:",
					currTile);
				break;
			}
			i++;
		}
		
		return addedTiles;
	}
	
	/**
	 * Calculates the set of tiles a unit can attack based on the contents of their moveTiles
	 * 	map. The procedure is straightforward: for each tile in the validMoves array, find all
	 * 	tiles within that unit's attack range by using getValidNeighbors. Then add those tiles
	 * 	to the unit's attackTiles map.
	 * 
	 * Isn't as nicely optimized as the functions that recalculate movement tiles. One attack
	 * 	tile will likely be visited many times over the course of the function.
	 * 
	 * @param	unit		The unit whose attack tiles are being calculated.
	 * @param	validMoves	The array of tiles that the attack ranges should be calculated from?
	 */
	public function calculateAttackTiles(unit:Unit, validMoves:Array<MoveID>):Void
	{
		unit.attackTiles = new Map<MoveID, Bool>();
		for (move in validMoves)
		{
			var validAttackTiles:Array<MoveID> = getValidNeighbors(move, unit.get_attackRanges(), 
				function(_, __){return true;});
			
			for (tile in validAttackTiles)
			{
				unit.attackTiles.set(tile, true);
			}
		}
	}
	
	/**
	 * Helper function used by tileBlockedRecalc() as its "test function" argument to 
	 * 	getValidNeighbors(). Considers the neighbor valid as long as it is within the
	 * 	unit's moveTiles.
	 * 
	 * Is used to identify that a the origin tile (an attack tile) is within the range
	 * 	of some valid movement tile.
	 * 
	 * @param	unit			The unit whose attack range is being recalculated.
	 * @param	neighborID		The tile that is checked to be within the unit's moveTiles.
	 * @param	dirFromOrigin	Not relevant for this function.
	 * @return	Whether the neighbor tile existed in unit's moveTiles.
	 */
	public function attackTileBlockedTest(unit:Unit, neighborID:MoveID, 
		dirFromOrigin:NeighborDirections):Bool
	{
		var result:Bool = false;
		
		if (unit.moveTiles.exists(neighborID))
			result = true;
		
		return result;
	}
	
	/**
	 * Recalculates a unit's valid attack tiles after some of the unit's move tiles become 
	 * 	blocked. To achieve this, all attack tiles that are within range of a removed movement
	 * 	tile search to see if there is another valid movement tile that is within range of them.
	 * 	If so, they can be retained, and if not they are removed.
	 * 
	 * Is only really efficient if range of attacks is smaller than unit's movement
	 * 	range. Which should pretty much always be the case.
	 * 
	 * I took a look at the complexity of this vs. just recalculating the whole set
	 * 	of attack tiles, and this is what I got:
	 * 
	 * 		Recalculating all attack tiles takes:
	 * 			(2m^2 + 2m) * [ (2r^2 + 2r) | 4r ]
	 * 		operations, where m is the unit's movement range and r is the unit's attack range.
	 * 		Use the left option for the "r" calculations if the range includes 1 to r, or use the
	 * 		right option if the unit can only attack things that are exactly r squares away.
	 * 
	 * 		Using this function takes:
	 * 			b * ( [(2r^2 + 2r) | 4r] )^2
	 * 		operations, where b is the number of tiles that were blocked and r is the unit's 
	 * 		attack range (see above for clarification of the "left" & "right" sides of "|").
	 * 
	 * 	From these equations, I drew the conclusion that as long as the attack range is 
	 * 		smaller than the unit's movement range and the number of blocked tiles is relatively
	 * 		small, this function should generally be faster. If the unit's attack range is of the
	 * 		"can only attack r squares away" variety, it is likely to be much, much faster.
	 * 	
	 * 	Note:	(2m^2 + 2m) represents the maximum number of movement tiles a unit will have in a
	 * 			"worst-case" scenario (no slowing terrain, so they can use their entire movement).
	 * 			In a situation where the unit's range is heavily limited by enemy units and/or
	 * 			terrain, this number will be much smaller than this estimate, which may make it
	 * 			faster than this function.
	 * 
	 * 			Also, all of the numbers that will actually be substutedin for m, r, and b are
	 * 			very small, so doing this sort of worst-case analysis is kinda silly. At runtime,
	 * 			both of these solutions are likely to run very, very fast. 
	 * 
	 * @param	unit			The unit whose attack range is being recalculated.
	 * @param	blockedMoves	Array of tiles that were blocked from the unit's MoveTiles map.
	 */
	public function tileBlockedRecalcAttack(unit:Unit, blockedMoves:Array<MoveID>):Void
	{
		var checkedAttackTiles:Map<MoveID, Bool> = new Map<MoveID, Bool>();
		
		for (move in blockedMoves)
		{
			var possiblyBlockedAttacks:Array<MoveID> = getValidNeighbors(move, 
				unit.get_attackRanges(), function(_, __){return true; });
			
			for (attack in possiblyBlockedAttacks)
			{
				if (!checkedAttackTiles.exists(attack))
				{
					var validMoveToAttackFrom:Array<MoveID> = getValidNeighbors(attack, 
						unit.get_attackRanges(), attackTileBlockedTest.bind(unit), true);
					
					if (validMoveToAttackFrom.length == 0)
					{
						unit.attackTiles.remove(attack);
					}
					
					checkedAttackTiles.set(attack, true);
				}
			}
		}
	}
	
	
	///////////////////////////////////////
	//      MOVEMENT PATH FUNCTIONS      //
	///////////////////////////////////////
	
	/**
	 * Hides arrow tiles by killing all currently alive ArrowTiles in the arrowTilePool.
	 */
	private function hideAllArrowTiles():Void
	{
		arrowTilePool.forEachAlive(function(arrowTile:FlxBasic){arrowTile.kill(); });
	}
	
	/**
	 * Clears the logical component of a unit's arrow/movePath.
	 * Separated from hideArrowTiles() because in some cases the arrow needs to be
	 * 	hidden while the path it represented needs to be remembered.
	 * 	e.g. during unit movement.
	 */
	private function clearMovePath():Void
	{
		movePath = movePath.splice(0, -1);
		totalPathCost = 0;
	}
	
	/**
	 * Converts an orthagonal neighborDirection (UP, DOWN, LEFT, RIGHT) to an equivalent string,
	 * 	all lower-case.
	 * 
	 * @param	dir	Orthagonal direction from NeighborDirections to be converted into string.
	 * @return	String representation of the passed-in neighbor direction.
	 */
	private function orthDirToString(dir:NeighborDirections):String
	{
		var result:String;
		switch (dir) 
		{
			case NeighborDirections.UP:
				result = "up";
			case NeighborDirections.DOWN:
				result = "down";
			case NeighborDirections.LEFT:
				result = "left";
			case NeighborDirections.RIGHT:
				result = "right";
			default:
				result = "non-orthagonal direction";
		}
		
		return result;
	}
	
	/**
	 * Finds the animation that should be played by an arrow tile if it is acting as the 
	 * 	arrowhead.
	 * 
	 * @param	arrowTile	arrowTile that needs its arrowhead animation.
	 * @param	prevMoveID	The moveID that came before arrowTile in the overall movePath.
	 * @return	String that identifies the correct animation the arrowTile should use.
	 */
	private function findMoveArrowAnim(arrowTile:ArrowTile, prevMoveID:MoveID):String
	{
		var dir:NeighborDirections = arrowTile.moveID.getDirFromOther(prevMoveID);
		return orthDirToString(dir);
	}
	
	/**
	 * Finds the animation that should be played by an arrow tile that is NOT acting as an
	 * 	arrowhead.
	 * 
	 * @param	arrowTile	arrowTile that needs its segment animation.
	 * @param	nextMoveID	the moveID that comes after arrowTile in the overall movePath.
	 * @param	prevMoveID	The moveID that came before arrowTile in the overall movePath.
	 * @return	String that identifies the correct animation the arrowTile should use.
	 */
	private function findMoveSegmentAnim(arrowTile:ArrowTile, nextMoveID:MoveID, 
		prevMoveID:MoveID)
	{
		var dirFromTile:NeighborDirections = nextMoveID.getDirFromOther(arrowTile.moveID);
		var dirToTile:NeighborDirections = arrowTile.moveID.getDirFromOther(prevMoveID);
		
		return orthDirToString(dirToTile) + "_" + orthDirToString(dirFromTile);
	}
	
	/**
	 * Finds array of NeighborDirections charting path from selectedUnit to moveID.
	 * Can be used to find an optimal movement path from a unit to a moveID.
	 * Used by enemy units that don't draw an arrow path prior to movement.
	 * 
	 * @param	targetMoveID	The moveID the selectedUnit is attempting to reach.
	 * @return	Array of NeighborDirections that describes the series of moves needed to reach
	 * 			the destination.
	 */
	private function findNeighborPathToTarget(targetMoveID:MoveID):
		Array<NeighborDirections>
	{
		var orderOfMoves:Array<NeighborDirections> = new Array<NeighborDirections>();
		var moveTile:PossibleMove = selectedUnit.moveTiles.get(targetMoveID);
		
		while (moveTile.direction != START)
		{
			orderOfMoves.push(moveTile.direction);
			var rowOffset:Int = 0;
			var colOffset:Int = 0;
			
			switch (moveTile.direction) 
			{
				case UP:
					rowOffset = 1;
				case DOWN:
					rowOffset = -1;
				case LEFT:
					colOffset = 1;
				case RIGHT:
					colOffset = -1;
				default:
					trace("ERROR: Non-orthagonal move provided to updateMoveArrow.");
			}
			
			var newMoveID:MoveID = moveTile.moveID.getOtherByOffset(rowOffset, colOffset);
			moveTile = selectedUnit.moveTiles.get(newMoveID);
		} 
		
		orderOfMoves.reverse();
		return orderOfMoves;
	}
	
	/**
	 * Updates the contents of the current movePath to draw an arrow from the selected unit
	 * 	to the passed-in ID.
	 * 
	 * See in-line documentation for implementation details.
	 * 
	 * @param	newMoveID	The MoveID that the arrow should extend/change to point at.
	 */
	public function updateMoveArrow(newMoveID:MoveID):Void
	{
		if (newMoveID.getRow() == selectedUnit.mapPos.getRow() && 
			newMoveID.getCol() == selectedUnit.mapPos.getCol())
		{
			// Cursor returned to starting space, clear the array and path cost.
			hideAllArrowTiles();
			clearMovePath();
		}
		else
		{
			// Check if the cursor moved back over an earlier point in the path
			var foundInPath:Int = -1;
			for (i in 0...movePath.length)
			{
				if (movePath[i].moveID == newMoveID)
				{
					foundInPath = i;
				}
			}
			
			// If it did...
			if (foundInPath != -1)
			{
				// subtract cost of subsequent moves from the total move cost and remove those
				//	moves.
				while (movePath.length > (foundInPath + 1))
				{
					movePath[movePath.length - 1].kill();
					var removedMoveID:MoveID = movePath.pop().moveID;
					totalPathCost -= 
						unitTerrainArr[removedMoveID.getRow()][removedMoveID.getCol()];
				}
				// and change the new end-of-arrow sprite to the appropriate arrow end.
				
				var prevLoc:MoveID = -1;
				
				if (movePath.length == 1)
				{
					prevLoc = MoveIDExtender.newMoveID(selectedUnit.mapPos.getRow(), selectedUnit.mapPos.getCol());
				}
				else if (movePath.length > 1)
				{
					prevLoc = movePath[movePath.length - 2].moveID;
				}
				
				movePath[movePath.length - 1].animation.play(
					findMoveArrowAnim(movePath[movePath.length - 1], prevLoc));
			}
			else
			{
				// Sets up prevLoc variable, which is needed in the upcoming if statement. 
				var prevLoc:MoveID = -1;
				
				if (movePath.length == 0)
				{
					prevLoc = MoveIDExtender.newMoveID(selectedUnit.mapPos.getRow(), selectedUnit.mapPos.getCol());
				}
				else if (movePath.length > 0)
				{
					prevLoc = movePath[movePath.length - 1].moveID;
				}
				
				// Else if the move doesn't push the total path cost past the unit's max move,
				// 	the move is in the unit's movement range, and newMoveID is orthagonally 
				// 	adjacent to the previous entry in the movePath
				if (totalPathCost + unitTerrainArr[newMoveID.getRow()][newMoveID.getCol()] <=
					selectedUnit.move && selectedUnit.moveTiles.exists(newMoveID) && 
					newMoveID.getDistFromOther(prevLoc) == 1) 
				{
					// The arrow should be extended according to the direction of movement.
					totalPathCost += unitTerrainArr[newMoveID.getRow()][newMoveID.getCol()];
					
					var prevPrevLoc:MoveID = -1;
					
					if (movePath.length == 1)
					{
						prevPrevLoc = 
							MoveIDExtender.newMoveID(selectedUnit.mapPos.getRow(), selectedUnit.mapPos.getCol());
					}
					else if (movePath.length > 1)
					{
						prevLoc = movePath[movePath.length - 1].moveID;
						prevPrevLoc = movePath[movePath.length - 2].moveID;
					}
					
					var newArrowTile:ArrowTile = cast arrowTilePool.recycle();
					
					newArrowTile.moveID = newMoveID;
					newArrowTile.animation.play(findMoveArrowAnim(newArrowTile, prevLoc));
					
					if (movePath.length > 0)
					{
						movePath[movePath.length - 1].animation.play(
							findMoveSegmentAnim(movePath[movePath.length - 1], newMoveID, 
							prevPrevLoc));
					}
					
					movePath.push(newArrowTile);
				}
				// Else if the move is reachable by the unit through a more optimal path
				else if (selectedUnit.moveTiles.exists(newMoveID))
				{
					// Re-draw the arrow using the optimal path
					// Update totalPathCost to match the optimal cost
					
					hideAllArrowTiles();
					clearMovePath();
					var orderOfMoves:Array<PossibleMove> = new Array<PossibleMove>();
					var moveTile:PossibleMove = selectedUnit.moveTiles.get(newMoveID);
					
					while (moveTile.direction != START)
					{
						orderOfMoves.push(moveTile);
						var rowOffset:Int = 0;
						var colOffset:Int = 0;
						
						switch (moveTile.direction) 
						{
							case UP:
								rowOffset = 1;
							case DOWN:
								rowOffset = -1;
							case LEFT:
								colOffset = 1;
							case RIGHT:
								colOffset = -1;
							default:
								trace("ERROR: Non-orthagonal move provided to updateMoveArrow.");
						}
						
						var newMoveID:MoveID = moveTile.moveID.getOtherByOffset(rowOffset, 
							colOffset);
						moveTile = selectedUnit.moveTiles.get(newMoveID);
						
					} 
					
					for (reverse_i in 0...(orderOfMoves.length))
					{
						var i = orderOfMoves.length - 1 - reverse_i;
						
						var newArrowTile:ArrowTile = cast arrowTilePool.recycle();
						newArrowTile.moveID = orderOfMoves[i].moveID;
						movePath.push(newArrowTile);
						
						if (i > 0)
						{
							// See ArrowTile.hx for documentation explaining why this works.
							newArrowTile.animation.play(
								orthDirToString(orderOfMoves[i].direction) + "_" + 
								orthDirToString(orderOfMoves[i - 1].direction));
						}
						else
						{
							newArrowTile.animation.play(
								orthDirToString(orderOfMoves[i].direction));
						}
					}
					totalPathCost = orderOfMoves[0].moveCost;
				}
				// Else, the move was invalid and not in the unit's move range, so no change should
				// 	occur.
			}
		}
	}
	
	///////////////////
	// UNIT MOVEMENT //
	///////////////////
	
	/**
	 * Identifies if the selected unit has finished traversing the path set out by its
	 * 	movePath. 
	 * 
	 * If it hasn't, this sets movement variables so later calls to moveUnit()
	 * 	will move the unit through the next segment of its overall move.
	 * 
	 * @return Whether the unit has finished moving or not.
	 */
	private function pickMoveViaMovePath():Bool
	{
		var finishedMoving:Bool = false;
		
		if (unitMovementIndex < movePath.length - 1)
		{
			unitMovementIndex++;
			var arrowAnim:String = movePath[unitMovementIndex].animation.name;
			selectedUnit.animation.play(arrowAnim.split("_")[0]);
			currMoveDir = selectedUnit.animation.name;
			framesLeftInMove = framesPerMove;
			remainingMoveDist = parentState.tileSize;
		}
		else
		{
			unitMovementIndex = -1;
			finishedMoving = true;
			currMoveFunction = null;
			currMoveDir = null;
			remainingMoveDist = 0;
		}
		
		return finishedMoving;
	}
	
	/**
	 * Identifies if the selected unit has finished traversing the path set out by its
	 * 	neighborPath. 
	 * 
	 * If it hasn't, this sets movement variables so later calls to moveUnit()
	 * 	will move the unit through the next segment of its overall move.
	 * 
	 * @return Whether the unit has finished moving or not.
	 */
	private function pickMoveViaNeighborPath():Bool
	{
		var finishedMoving:Bool = false;
		
		if (unitMovementIndex < neighborPath.length - 1)
		{
			unitMovementIndex++;
			selectedUnit.animation.play(orthDirToString(neighborPath[unitMovementIndex]));
			currMoveDir = selectedUnit.animation.name;
			framesLeftInMove = framesPerMove;
			remainingMoveDist = parentState.tileSize;
		}
		else
		{
			unitMovementIndex = -1;
			finishedMoving = true;
			currMoveFunction = null;
			currMoveDir = null;
			remainingMoveDist = 0;
		}
		
		return finishedMoving;
	}
	
	/**
	 * Incrementally moves a unit based on this object's current set of movement-related 
	 * 	variables.
	 */
	private function moveUnit():Void
	{
		var vertMod:Int = 0;
		var horizMod:Int = 0;
		
		switch(currMoveDir)
		{
			case "up":
				vertMod = -1;
			case "down":
				vertMod = 1;
			case "left":
				horizMod = -1;
			case "right":
				horizMod = 1;
			default:
				trace("ERROR: currMoveDir was not a string representation of a direction.");
		}
		
		var moveDist:Float = remainingMoveDist / framesLeftInMove;
		
		remainingMoveDist -= moveDist;
		framesLeftInMove--;
		
		selectedUnit.x += horizMod * moveDist;
		selectedUnit.y += vertMod * moveDist;
	}
	
	
	/////////////////////
	// UPDATE FUNCTION //
	/////////////////////
	
	/**
	 * Should be called each frame inside the MissionState's update function.
	 * Is responsible for doing incremental changes during unit movement.
	 * 
	 * @param	elapsed	Time (in seconds) since the last call to update().
	 */
	public function update(elapsed:Float)
	{
		var finishedMoving:Bool = false;
		
		if (currMoveFunction != null && framesLeftInMove == 0)
		{
			finishedMoving = currMoveFunction();
		}
		
		if (framesLeftInMove > 0)
		{
			moveUnit();
		}
		
		if (finishedMoving)
		{
			clearMovePath();
			parentState.unitMovementFinished();
		}
	}
	
}