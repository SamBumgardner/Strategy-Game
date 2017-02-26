package;

import flixel.FlxGame;
import missions.MissionState;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(1280, 960, missions.MissionState));
	}
}