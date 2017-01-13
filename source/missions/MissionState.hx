package missions;

import boxes.ResizeableBox;
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
class MissionState extends FlxState implements Observer
{
	
	private var map:StrategyOgmoLoader;
	private var terrainTiles:FlxTilemap;
	
	public var terrainArray:Array<Array<Int>>;
	public var mapCursor:MapCursor;
	
	private var mapCursorManager:MapCursorManager;
	
	public var tileSize(default, never):Int = 64;
	private var deadzoneBorderTiles(default, never) = 2;
	
	private var menu:BasicMenu;
	private var menu2:BasicMenu;
	private var menu3:BasicMenu;
	private var menu4:BasicMenu;
	
	private var resizeableBox:ResizeableBox;
	
	private var updateableObjects:Array<UpdatingEntity> = new Array<UpdatingEntity>();
	private var currentlyUpdatingIndex:Int = 0;

	
	override public function create():Void
	{	
		MoveInputHandler.init(FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT);
		ActionInputHandler.init([FlxKey.Z, FlxKey.X, FlxKey.C, FlxKey.S, FlxKey.D]);
		
		initMap();
		initMapCursor();
		
		initCamera();
		
		initManagers();
		
		resizeableBox = new ResizeableBox(300, 300, AssetPaths.box_test__png, 15, 15);
		add(resizeableBox.totalFlxGrp);
		
		menu = new BasicMenu(50, 100, ["Unit", "Status", "Options", "Suspend", "End"], 1);
		menu.subject.addObserver(this);
		add(menu.totalFlxGrp);
		
		menu2 = new BasicMenu(200, 20, ["Item", "Trade", "Wait"], 2);
		menu2.subject.addObserver(this);
		add(menu2.totalFlxGrp);
		
		menu3 = new BasicMenu(200, 150, ["Equip", "Trade", "Discard", "This is a really long menu entry!"], 3);
		menu3.subject.addObserver(this);
		add(menu3.totalFlxGrp);
		
		menu4 = new BasicMenu(400, 30, ["Smile", "Jump", "Wear Hat", "Nose", "Clap", "PSI Rockin'", "Stomp"], 4);
		menu4.subject.addObserver(this);
		add(menu4.totalFlxGrp);
		
		updateableObjects.push(menu);
		updateableObjects.push(menu2);
		updateableObjects.push(menu3);
		updateableObjects.push(menu4);
		
		updateableObjects[currentlyUpdatingIndex].active = true;
		
		
		super.create();
	}
	
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
	 * Must be called after MapCursor has been created, which should happen in initMap().
	 * 
	 * This function is not included in the section of placeEntities that creates the 
	 * 	MapCursor because we may not want to add the contents of its totalFlxGrp and
	 * 	push it into updateable objects in the same order that objects are created in 
	 * 	placeEntities.
	 */
	private function initMapCursor():Void
	{
		add(mapCursor.totalFlxGrp);
		updateableObjects.push(mapCursor);
	}
	
	/**
	 * Must be called after mapCursor has been created, which should happen in initMap().
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
	
	private function placeEntitites(entityName:String, entityData:Xml):Void
	{
		var x:Int = Std.parseInt(entityData.get("x"));
		var y:Int = Std.parseInt(entityData.get("y"));
		if (entityName == "map_cursor")
		{
			mapCursor = new MapCursor(map.width, map.height, 0);
			mapCursor.subject.addObserver(this);
			
			var row:Int = Math.floor(y / tileSize);
			var col:Int = Math.floor(x / tileSize);
			mapCursor.jumpToPosition(row, col);
		}
	}
	
	private function initManagers():Void
	{
		mapCursorManager = new MapCursorManager(this);
	}
	
	
	/* INTERFACE observerPattern.Observer */
	
	// Not final code for MissionState. Just here for ease of testing at the moment.
	
	public function onNotify(event:InputEvent, notifier:Observed)
	{
		trace("Recieved an event with id", event.getID(), "and type", event.getType());
		
		if (event.getType() == EventTypes.CONFIRM)
		{
			if (Std.is(notifier, MenuTemplate))
			{
				trace("The selected MenuOption was: " + (cast notifier).currMenuOption.label.text);
			}
			
			updateableObjects[currentlyUpdatingIndex].deactivate();
			(cast updateableObjects[currentlyUpdatingIndex]).hide();
			currentlyUpdatingIndex++;
			
			if (currentlyUpdatingIndex == updateableObjects.length)
			{
				mapCursor.changeInputModes(InputModes.FREE_MOVEMENT);
				currentlyUpdatingIndex = 0;
			}
			else
			{
				mapCursor.changeInputModes(InputModes.DISABLED);
			}
			
			updateableObjects[currentlyUpdatingIndex].activate();
			(cast updateableObjects[currentlyUpdatingIndex]).reveal();
			MoveInputHandler.resetNumVars();
			ActionInputHandler.resetNumVars();
		}
		else if (event.getType() == EventTypes.CANCEL)
		{
			updateableObjects[currentlyUpdatingIndex].deactivate();
			(cast updateableObjects[currentlyUpdatingIndex]).hide();
			
			mapCursor.changeInputModes(InputModes.FREE_MOVEMENT);
			currentlyUpdatingIndex = 0;
			
			updateableObjects[currentlyUpdatingIndex].activate();
			(cast updateableObjects[currentlyUpdatingIndex]).reveal();
			MoveInputHandler.resetNumVars();
			ActionInputHandler.resetNumVars();
		}
	}
	
	override public function update(elapsed:Float):Void
	{
		if (FlxG.keys.justPressed.Q)
		{
			resizeableBox.resize(resizeableBox.boxWidth - 30, resizeableBox.boxHeight - 30);
		}
		if (FlxG.keys.justPressed.W)
		{
			resizeableBox.resize(resizeableBox.boxWidth + 30, resizeableBox.boxHeight + 30);
		}
		
		ActionInputHandler.bufferActions(elapsed);
		super.update(elapsed);
		updateableObjects[currentlyUpdatingIndex].update(elapsed);
		MoveInputHandler.updateCycleFinished();
		ActionInputHandler.updateCycleFinished();
	}
	
}