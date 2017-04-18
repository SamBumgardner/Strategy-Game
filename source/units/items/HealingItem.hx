package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class HealingItem extends EquippableItem
{
	public function new(rangeArr:Array<Int>) 
	{
		super(rangeArr, ItemTypes.HEALING);
		
	}
	
}