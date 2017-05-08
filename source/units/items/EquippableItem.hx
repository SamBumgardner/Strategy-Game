package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class EquippableItem extends Item
{

	public var weight:Int = 4;
	public var accuracy:Int = 80;
	public var damage:Int = 5;
	public var critChance:Int = 15;
	
	
	public function new(itemName:String, rangeArr:Array<Int>, type:ItemTypes) 
	{
		super(itemName, rangeArr, type);
	}
	
}