package;

import flixel.input.keyboard.FlxKey;
import inputHandlers.MoveInputHandler;
import boxes.BoxCreator;
import cursors.MapCursor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.math.FlxMath;

class MenuState extends FlxState
{
	private var mapCursor:MapCursor;
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
		
		mapCursor = new MapCursor();
		add(mapCursor.getTotalFlxGroup());
		
		BoxCreator.setBoxType(AssetPaths.box_test__png, 15, 15);
		add(BoxCreator.createBox(55, 150));
		BoxCreator.setBoxType(AssetPaths.box_big_bg__png, 15, 45);
		var secondBox:FlxSprite = BoxCreator.createBox(300, 200);
		secondBox.x = 300;
		secondBox.y = 200;
		add(secondBox);
		
		MoveInputHandler.setMoveKeys(FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		mapCursor.update(elapsed);
		MoveInputHandler.updateCycleFinished();
	}
}