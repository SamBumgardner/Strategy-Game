package missions;

import boxes.ResizableBox;
import cursors.MapCursor;
import flixel.FlxG;
import flixel.FlxState;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxRect;
import flixel.tile.FlxTilemap;
import inputHandlers.ActionInputHandler;
import inputHandlers.MoveInputHandler;
import menus.BasicMenu;
import menus.MenuTemplate;
import menus.MissionMenuTypes;
import menus.ResizableBasicMenu;
import missions.managers.MapCursorManager;
import missions.managers.MenuManager;
import missions.managers.UnitManager;
import observerPattern.Observer;
import observerPattern.eventSystem.EventTypes;
import observerPattern.eventSystem.InputEvent;
import units.MapCursorUnitTypes;
import units.MoveID;
import units.Unit;
import utilities.StrategyOgmoLoader;
import utilities.UpdatingEntity;

using observerPattern.eventSystem.EventExtender;
using units.MoveIDExtender;

/**
 * Instantiates and coordinates all of the game components of the
 * 	mission part of gameplay, which is where the meat of the action is.
 * 
 * Will use manager classes to handle the fine components, mostly acting
 * 	as an public interface for all of its managers to access and call
 * 	functions on to manage the overall flow of gameplay.
 * 
 * @author Samuel Bumgardner
 */
class MissionState extends FlxState
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Used to load level & terrain data from .oel file.
	 */
	private var map:StrategyOgmoLoader;
	
	/**
	 * Tilemap of the map background. Generated from the level's "visual" tilemap data.
	 */
	private var terrainTiles:FlxTilemap;
	
	/**
	 * 2-D array that represents the map's tactical terrain info.
	 * Its values correspond entries in the TerrainTypes enum.
	 */
	public var terrainArray:Array<Array<Int>>;
	
	/**
	 * The cursor used to select player controlled units and do pretty much all gameplay
	 * 	outside of menus.
	 */
	public var mapCursor:MapCursor;
	
	/**
	 * Manages the mapCursor and respond to its events.
	 */
	private var mapCursorManager:MapCursorManager;
	
	/**
	 * Manages all menus and responds to their events.
	 */
	private var menuManager:MenuManager;
	
	/**
	 * Manages all units and responds to their events.
	 */
	private var unitManager:UnitManager;
	
	/**
	 * Size of the map's tiles, measured in pixels.
	 */
	public var tileSize(default, never):Int = 64;
	
	/**
	 * Number of tiles between the edge of the screen and the camera's dead zone.
	 */
	private var deadzoneBorderTiles(default, never) = 2;
	
	/**
	 * Non-HaxeFlixel inherting, input-consuming object that is currently updating. 
	 * Usually is the component of the game that the player is currently interacting with.
	 */
	private var currentlyUpdatingObject:UpdatingEntity;
	
	/**
	 * Tracks the state of the Mission. Determines what should be displayed and how
	 * 	input should be interpreted.
	 */
	public var controlState(default, null):PlayerControlStates = PlayerControlStates.FREE_MOVE;

	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer (more or less).
	 */
	override public function create():Void
	{	
		MoveInputHandler.init(FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT);
		ActionInputHandler.init([FlxKey.Z, FlxKey.X, FlxKey.C, FlxKey.S, FlxKey.D]);
		
		initMap();
		
		initCamera();
		
		initManagers();
		
		addAllFlxObjects();
		
		mapCursorManager.activateMapCursor();
		
		super.create();
	}
	
	/**
	 * Initializes map, which includes the following:
	 * 	Generates visual tilemap.
	 * 	Generates 2-D array of tactical terrain info.
	 * 	Generates all entities specified in the mission's .oel file. 
	 */
	private function initMap():Void
	{
		map = new StrategyOgmoLoader(AssetPaths.forest_1__oel);
		terrainTiles = map.loadTilemap(AssetPaths.terrain_forest__png, 64, 64, "terrain_visual");
		terrainTiles.follow();
		add(terrainTiles);
		
		terrainArray = map.loadTerrainArray("terrain_strategic", tileSize);
		initMoveIDExtender();
		
		map.loadEntities(placeEntitites, "entities");
	}
	
	private function initMoveIDExtender():Void
	{
		MoveIDExtender.numRows = terrainArray.length;
		MoveIDExtender.numCols = terrainArray[0].length;
	}
	
	/**
	 * Initializes the mission's camera, which involves the following:
	 * 	Sets the camera to follow the mapCursor.
	 * 	Creates camera deadzone in the middle of the screen.
	 * 		The size of the border around the deadzone area is determined by deadzoneBorderTiles.
	 * 
	 * NOTE:
	 * 	Must be called after mapCursor has been created, which should happen in initMap().
	 * 	Otherwise, the camera won't be able to follow mapCursor's cameraHitbox.
	 */
	private function initCamera():Void
	{
		if (mapCursor == null)
		{
			trace("ERROR: Camera could not be set up because mapCursor was not created before " +
				"initCamera() was called.");
		}
		else
		{
		FlxG.camera.follow(mapCursor.cameraHitbox, 1);
		FlxG.camera.deadzone = new FlxRect (tileSize * deadzoneBorderTiles, 
			tileSize * deadzoneBorderTiles, FlxG.width - deadzoneBorderTiles * tileSize * 2,
			FlxG.height - deadzoneBorderTiles * tileSize * 2);
		}
	}
	
	/**
	 * Generates all objects specified in the mission's .oel file.
	 * 
	 * @param	entityName	The name of the entity from the .oel file.
	 * @param	entityData	Any accompanying data for that entity from the .oel file.
	 */
	private function placeEntitites(entityName:String, entityData:Xml):Void
	{
		var x:Int = Std.parseInt(entityData.get("x"));
		var y:Int = Std.parseInt(entityData.get("y"));
		if (entityName == "map_cursor")
		{
			mapCursor = new MapCursor(map.width, map.height, 0);
			
			var row:Int = Math.floor(y / tileSize);
			var col:Int = Math.floor(x / tileSize);
			mapCursor.jumpToPosition(row, col);
		}
	}
	
	/**
	 * Initializes all manager-type objects.
	 */
	private function initManagers():Void
	{
		mapCursorManager = new MapCursorManager(this);
		menuManager = new MenuManager(this);
		unitManager = new UnitManager(this);
	}
	
	/**
	 * Adds all HaxeFlixel-inheriting object to the scene in the correct order.
	 * Since all of these objects will be controlled some sort of manager, this function just
	 * 	has to add the totalFlxGrps of all if the state's manager objects.
	 */
	private function addAllFlxObjects():Void
	{
		add(unitManager.totalFlxGrp);
		add(mapCursor.totalFlxGrp);
		add(menuManager.totalFlxGrp);
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Uses manager objects to identify how to respond to the input, then call the 
	 * 	appropriate manager functions to carry out that response.
	 * 
	 * If the cursor is over an active player unit, the unit action menu should open.
	 * If the cursor is over an inactive player unit, then the map action menu should open.
	 * If the cursor is over an enemy unit, the enemy's attack range should be displayed.
	 * If the cursor is over no unit, then the map action menu should open.
	 */
	public function isMapCursorOverUnit():MapCursorUnitTypes
	{
		var targetRow:Int = mapCursorManager.mapCursor.row;
		var targetCol:Int = mapCursorManager.mapCursor.col;
		
		var targetUnit:Unit = unitManager.getUnitAtLoc(targetRow, targetCol);
		
		// Update the unitManager's hovered unit variable.
		unitManager.changeHoveredUnit(targetUnit);
		
		var targetUnitType:MapCursorUnitTypes;
		
		if (targetUnit != null)
		{
			if(targetUnit.team == TeamType.PLAYER)
			{
				if (targetUnit.canAct == true)
				{
					// Need to set some variable so game knows which unit is active.
					targetUnitType = MapCursorUnitTypes.PLAYER_ACTIVE;
				}
				else
				{
					targetUnitType = MapCursorUnitTypes.PLAYER_INACTIVE;
				}
			}
			else // target unit is on neutral or enemy team
			{
				targetUnitType = MapCursorUnitTypes.NOT_PLAYER;
			}
		}
		else
		{
			targetUnitType = MapCursorUnitTypes.NONE;
		}
		
		return targetUnitType;
	}
	
	/**
	 * 
	 */
	public function calculateNewMoveArrow()
	{
		var verticalMove:Int = 
			mapCursorManager.currCursorPos.getRow() - mapCursorManager.prevCursorPos.getRow();
		
		var horizontalMove:Int = 
			mapCursorManager.currCursorPos.getCol() - mapCursorManager.prevCursorPos.getCol();
		
		if (Math.abs(verticalMove + horizontalMove) == 1)
		{
			unitManager.updateMoveArrow(mapCursorManager.currCursorPos);
		}
		else
		{
			// The cursor moved diagonally, so do 2 separate updateMoveArrow calls.
			unitManager.updateMoveArrow(
				mapCursorManager.prevCursorPos.getOtherByOffset(verticalMove, 0));
			
			unitManager.updateMoveArrow(
				mapCursorManager.prevCursorPos.getOtherByOffset(verticalMove, horizontalMove));
		}
	}
	
	public function mapCursorConfirm()
	{
		if (controlState == PlayerControlStates.FREE_MOVE)
		{
			if (mapCursorManager.hoveredUnitType == PLAYER_ACTIVE)
			{
				controlState = PlayerControlStates.PLAYER_UNIT;
				mapCursorManager.unitSelected(unitManager.hoveredUnit);
				unitManager.unitSelected(unitManager.hoveredUnit);
			}
			else if (mapCursorManager.hoveredUnitType == NOT_PLAYER)
			{
				controlState = PlayerControlStates.OTHER_UNIT;
				mapCursorManager.unitSelected(unitManager.hoveredUnit);
				unitManager.unitSelected(unitManager.hoveredUnit);
			}
			else
			{
				controlState = PlayerControlStates.MAP_MENU;
				openTopLevelMenu(MissionMenuTypes.MAP_ACTION);
			}
		}
		else if (controlState == PlayerControlStates.OTHER_UNIT)
		{
			controlState = PlayerControlStates.FREE_MOVE;
			mapCursorManager.unitUnselected();
			unitManager.unitUnselected();
		}
		
	}
	
	/**
	 * Order that unitUnselecteds are called matters.
	 */
	public function mapCursorCancel()
	{
		if (controlState == PlayerControlStates.PLAYER_UNIT || 
			controlState == PlayerControlStates.OTHER_UNIT)
		{
			controlState = PlayerControlStates.FREE_MOVE;
			unitManager.unitUnselected();
			mapCursorManager.unitUnselected();
		}
	}
	
	/**
	 * Public interface that allows external classes to request that a top-level menu be opened.
	 */
	public function openTopLevelMenu(menuType:Int):Void
	{
		menuManager.openTopLevelMenu(menuType);
	}
	
	/**
	 * Calls any manager functions necessary to transition from all menus being closed
	 * 	to at least one being open.
	 * 
	 * @param	newMenu	The menu that was opened.
	 */
	public function firstMenuOpened(newMenu:MenuTemplate):Void
	{
		mapCursorManager.deactivateMapCursor();
		menuManager.changeMenuXPositions(!mapCursorManager.cursorOnLeft);
	}
	
	/**
	 * Calls any manager functions necessary to transition from menus being open to
	 * 	all menus being closed.
	 * 
	 * At the moment, that just involves activating the mapCursor.
	 * 
	 * NOTE:
	 * 	May need to have special behavior when the unit menu was closed.
	 * 	Shouldn't go back to just free map cursor, should go back to unit being selected
	 * 	(or special behavior for a move-again type character).
	 */
	public function allMenusClosed(closedByCancel:Bool):Void
	{
		if (controlState == PlayerControlStates.MAP_MENU)
		{
			controlState = PlayerControlStates.FREE_MOVE;
			mapCursorManager.activateMapCursor();
		}
		if (controlState == PlayerControlStates.UNIT_MENU) 
		{
			if (closedByCancel)
			{
				controlState = PlayerControlStates.PLAYER_UNIT;
				unitManager.undoUnitMove();
				mapCursorManager.activateMapCursor();
				mapCursorManager.jumpToUnit(unitManager.selectedUnit);
				
				mapCursorManager.unitSelected(unitManager.hoveredUnit);
				unitManager.unitSelected(unitManager.hoveredUnit);
			}
			else
			{
				controlState = PlayerControlStates.FREE_MOVE;
				mapCursorManager.activateMapCursor();
				unitManager.updateUnitPos(unitManager.selectedUnit, mapCursor.row, mapCursor.col);
				unitManager.unitUnselected();
				mapCursorManager.unitUnselected();
			}
		}
	}
	
	/**
	 * Changes the object currentlyUpdatingObject references & calls the input handlers'
	 * 	reset functions.
	 * @param	newObj
	 */
	public function changeCurrUpdatingObj(newObj:UpdatingEntity):Void
	{
		currentlyUpdatingObject = newObj;
		ActionInputHandler.resetNumVars();
		MoveInputHandler.resetNumVars();
	}
	
	///////////////////////////////////////
	//         UPDATE FUNCTIONS          //
	///////////////////////////////////////
	
	/**
	 * Updates all entities in the scene.
	 * Additionally, it calls update functions for any objects that aren't automatically
	 * 	updated during super.update(), i.e. input handlers and the currentlyUpdating object.
	 * 
	 * @param	elapsed	Time passed since last call to update, in seconds.
	 */
	override public function update(elapsed:Float):Void
	{
		ActionInputHandler.bufferActions(elapsed);
		super.update(elapsed);
		currentlyUpdatingObject.update(elapsed);
		MoveInputHandler.updateCycleFinished();
		ActionInputHandler.updateCycleFinished();
	}
	
}