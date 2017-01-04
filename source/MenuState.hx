package;

import flixel.input.keyboard.FlxKey;
import inputHandlers.MoveInputHandler;
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
		
		
		MoveInputHandler.setMoveKeys(FlxKey.UP, FlxKey.DOWN, FlxKey.LEFT, FlxKey.RIGHT);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		mapCursor.update(elapsed);
		MoveInputHandler.updateCycleFinished();
	}
}