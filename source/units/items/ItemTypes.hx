package units.items;

/**
 * Enum that defines different categories of items.
 * 
 * WEAPON: An item used in combat, but may have secondary uses. May be repaired. Equippable.
 * HEALING: An item used outside of combat specifically to heal others. Equippable. 
 * TOOL: An item used outside of combat. May be repaired. Not equippable.
 * CONSUMABLE: An item used outside of combat that is consumed through use. May not be repaired. Not equippable.
 * OTHER: A catch-all for other item types, like ones that give a passive bonus to the bearer. Not equippable.
 * DUMMY: A "fake" item temporarily added to inventories when trading.
 * @author Samuel Bumgardner
 */
enum ItemTypes 
{
	WEAPON;
	HEALING;
	TOOL;
	CONSUMABLE;
	OTHER;
	DUMMY;
}