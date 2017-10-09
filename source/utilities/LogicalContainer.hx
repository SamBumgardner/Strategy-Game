package utilities;

/**
 * @author Samuel Bumgardner
 */
interface LogicalContainer 
{
	public var x(default, null):Float;
	public var y(default, null):Float;
	
	public function setPos(newX:Float, newY:Float):Void;
	public function updateLogicalPos(xDiff:Float, yDiff:Float):Void;
}