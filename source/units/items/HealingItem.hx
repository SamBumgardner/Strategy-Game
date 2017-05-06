package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class HealingItem extends EquippableItem
{
	public function new(itemName:String, rangeArr:Array<Int>) 
	{
		super(itemName, rangeArr, ItemTypes.HEALING);
		
	}
	
}