package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class WeaponItem extends EquippableItem
{
	
	public function new(rangeArr:Array<Int>) 
	{
		super(rangeArr, ItemTypes.WEAPON);
		
	}
	
}