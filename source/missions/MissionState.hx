package missions;

import boxes.ResizableBox;
import cursors.MapCursor;
import flixel.FlxG;
import flixel.FlxState;
import flixel.group.FlxGroup;
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
import observerPattern.Observed;
import observerPattern.Observer;
import observerPattern.eventSystem.EventTypes;
import observerPattern.eventSystem.InputEvent;
import utilities.StrategyOgmoLoader;
import utilities.UpdatingEntity;

using observerPattern.eventSystem.EventExtender;

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
		terrainTiles = map.loadTilemap(AssetPaths.terrain_forest__png,
			tileSize, tileSize, "terrain_visual");
		terrainTiles.follow();
		add(terrainTiles);
		
		terrainArray = map.loadTerrainArray("terrain_strategic", tileSize);
		
		map.loadEntities(placeEntitites, "entities");
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
			var deadzoneWidth:Int = tileSize * deadzoneBorderTiles;
			FlxG.camera.follow(mapCursor.cameraHitbox, 1);
			FlxG.camera.deadzone = new FlxRect (deadzoneWidth, deadzoneWidth,
				FlxG.width - deadzoneWidth * 2,
				FlxG.height - deadzoneWidth * 2);
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
	}
	
	/**
	 * Adds all HaxeFlixel-inheriting object to the scene in the correct order.
	 * Since all of these objects will be controlled some sort of manager, this function just
	 * 	has to add the totalFlxGrps of all if the state's manager objects.
	 */
	private function addAllFlxObjects():Void
	{
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
	 * If the cursor is over a player unit, the unit action menu should open.
	 * If the cursor is over an enemy unit, the enemy's attack range should be displayed.
	 * If the cursor is over no unit, then the map action menu should open.
	 */
	public function mapCursorConfirmPressed():Void
	{
		menuManager.openTopLevelMenu(MissionMenuTypes.UNIT_ACTION);
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
	public function allMenusClosed():Void
	{
		mapCursorManager.activateMapCursor();
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