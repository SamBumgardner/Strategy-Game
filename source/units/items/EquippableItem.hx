package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class EquippableItem extends Item
{

	public var weight:Int = 4;
	
	public function new(itemName:String, rangeArr:Array<Int>, type:ItemTypes) 
	{
		super(itemName, rangeArr, type);
	}
	
}