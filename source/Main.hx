package;

import flixel.FlxGame;
import missions.MissionState;
import openfl.display.Sprite;

class Main extends Sprite
{
	public function new()
	{
		super();
		addChild(new FlxGame(640, 480, missions.MissionState));
	}
}