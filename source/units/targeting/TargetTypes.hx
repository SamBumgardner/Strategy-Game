package units.targeting;

/**
 * Enum that defines different sets of valid targets a unit-targeting thing may have.
 * 
 * SELF: 	This may only target the already-selected unit.
 * OTHER:	This may target any unit besides the already-selected unit.
 * ALLY: 	This may target any allied unit besides the already-selected unit.
 * ENEMY:	This may target any non-allied unit.
 * 
 * SELF_ALLY, SELF_ENEMY, SELF_OTHER:	These are combinations of the above categories.
 * 
 * NONE: 	This may not target any unit. Basically a "null" value.
 * 
 * @author Samuel Bumgardner
 */
enum TargetTypes 
{
	SELF;
	OTHER;
	ALLY;
	ENEMY;
	SELF_ALLY;
	SELF_ENEMY;
	SELF_OTHER;
	NONE;
}