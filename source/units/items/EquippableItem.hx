package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class EquippableItem extends Item
{

	public var weight:Int = 4;
	
	public function new(rangeArr:Array<Int>, type:ItemTypes) 
	{
		super(rangeArr, type);
	}
	
}