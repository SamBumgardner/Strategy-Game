package units.items;

/**
 * ...
 * @author Samuel Bumgardner
 */
class WeaponItem extends EquippableItem
{
	
	public function new(itemName:String, rangeArr:Array<Int>) 
	{
		super(itemName, rangeArr, ItemTypes.WEAPON);
		
	}
	
	override public function insertIntoInv(targetInv:Inventory, targetIndex:Int):Void
	{
		super.insertIntoInv(targetInv, targetIndex);
		// If the weapon is equippable and its new index isn't in the list of weapon indices...
		if (targetInv.owner.canEquipItem(this) && 
			targetInv.weaponIndices.indexOf(targetIndex) == -1)
		{
			// Add this new index to the list of weapon indices.
			targetInv.weaponIndices.push(targetIndex);
		}
	}
	
}