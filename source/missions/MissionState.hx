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
import menus.ResizableBasicMenu;
import missions.managers.MapCursorManager;
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
	 * Size of the map's tiles, measured in pixels.
	 */
	public var tileSize(default, never):Int = 64;
	
	/**
	 * Number of tiles between the edge of the screen and the camera's dead zone.
	 */
	private var deadzoneBorderTiles(default, never) = 2;
	

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
		
		map.loadEntities(placeEntitites, "entities");
	}
	
	/**
	 * 
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
	}
	
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	{
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
		MoveInputHandler.updateCycleFinished();
		ActionInputHandler.updateCycleFinished();
	}
	
}