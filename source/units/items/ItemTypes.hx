package units.items;

/**
 * Enum that defines different categories of items.
 * 
 * WEAPON: An item used in combat, but may have secondary uses. May be repaired.
 * TOOL: An item used outside of combat. May be repaired.
 * CONSUMABLE: An item used outside of combat that is consumed through use. May not be repaired.
 * OTHER: A catch-all for other item types, like ones that give a passive bonus to the bearer.
 * 
 * @author Samuel Bumgardner
 */
enum ItemTypes 
{
	WEAPON;
	TOOL;
	CONSUMABLE;
	OTHER;
}