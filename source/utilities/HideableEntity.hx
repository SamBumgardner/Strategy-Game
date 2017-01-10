package utilities;

/**
 * Interface for any object that needs to hide and reveal itself and/or its components on demand.
 * This isn't really necessary for any object that inherits from FlxSprite, since it already has
 * 	the visible property. Instead, this should be used by objects that create and manage a 
 * 	collection of graphics-using components and are going to need a function to hide all of
 * 	those graphics-using components at once.
 * 
 * @author Samuel Bumgardner
 */
interface HideableEntity 
{
	public function hide():Void;
	public function reveal():Void;
}