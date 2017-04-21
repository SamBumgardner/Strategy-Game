package;

import flixel.input.keyboard.FlxKey;
import inputHandlers.ActionInputHandler;
import inputHandlers.MoveInputHandler;
import boxes.BoxCreator;
import menus.cursorMenus.BasicMenu;
import cursors.MapCursor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;
import menus.cursorMenus.CursorMenuTemplate;
import observerPattern.eventSystem.InputEvent;
import observerPattern.eventSystem.EventTypes;
import observerPattern.Observed;
import observerPattern.Observer;
import utilities.UpdatingEntity;

using observerPattern.eventSystem.EventExtender;

/**
 * Currently a test bed for new features. 
 * The code below is not meant to be permanent, it's just there to test and show off the
 * components of the game that I'm currently working on.
 */

class MenuState extends FlxState implements Observer
{
	private var mapCursor:MapCursor;
	private var menu:BasicMenu;
	private var menu2:BasicMenu;
	private var menu3:BasicMenu;
	private var menu4:BasicMenu;
	
	private var updateableObjects:Array<UpdatingEntity> = new Array<UpdatingEntity>();
	private var currentlyUpdatingIndex:Int = 0;
	
	override public function create():Void
	{
		super.create();
		
		for (col in 0...10)
		{
			for (row in 0...10)
			{
				var groundTile = new FlxSprite(64 * col, 64 * row);
				groundTile.makeGraphic(64, 64, FlxG.random.int(0, 0xFFFFFFFF));
				add( groundTile);
			}
		}
		
		mapCursor = new MapCursor(0);
		mapCursor.subject.addObserver(this);
		add(mapCursor.getTotalFlxGroup());
		
		BoxCreator.setBoxType(AssetPaths.box_test__png, 15, 15);
		add(BoxCreator.createBox(55, 150));
		BoxCreator.setBoxType(AssetPaths.box_big_bg__png, 15, 45);
		var secondBox:FlxSprite = BoxCreator.createBox(300, 200);
		secondBox.x = 300;
		secondBox.y = 200;
		add(secondBox);
		
		MoveInputHandler.init(FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT);
		ActionInputHandler.init([FlxKey.Z, FlxKey.X, FlxKey.C, FlxKey.S, FlxKey.D]);
		
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
		
		updateableObjects.push(mapCursor);
		updateableObjects.push(menu);
		updateableObjects.push(menu2);
		updateableObjects.push(menu3);
		updateableObjects.push(menu4);
		
		updateableObjects[currentlyUpdatingIndex].active = true;
	}
	
	public function onNotify(event:InputEvent, notifier:Observed)
	{
		trace("Recieved an event with id", event.getID(), "and type", event.getType());
		
		if (event.getType() == EventTypes.CONFIRM)
		{
			if (Std.is(notifier, CursorMenuTemplate))
			{
				trace("The selected MenuOption was: " + (cast notifier).currMenuOption.label.text);
			}
			
			updateableObjects[currentlyUpdatingIndex].deactivate();
			(cast updateableObjects[currentlyUpdatingIndex]).hide();
			currentlyUpdatingIndex++;
			
			if (currentlyUpdatingIndex == updateableObjects.length)
			{
				currentlyUpdatingIndex = 0;
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
			
			currentlyUpdatingIndex = 0;
			
			updateableObjects[currentlyUpdatingIndex].activate();
			(cast updateableObjects[currentlyUpdatingIndex]).reveal();
			MoveInputHandler.resetNumVars();
			ActionInputHandler.resetNumVars();
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		updateableObjects[currentlyUpdatingIndex].update(elapsed);
		MoveInputHandler.updateCycleFinished();
		ActionInputHandler.updateCycleFinished();
	}
}