package missions;

/**
 * Set of states that the MissionState may be in. 
 * Determines what should be displayed on the screen and how player input should be interpreted.
 * 
 * I'll include a brief description of each of the states below:
 * 
 * FREE_MOVE:	The default interaction state between player and mission state.
 * 				The player may freely move the mapCursor, and from here may 
 * 				select units, look at their information or open the map menu.
 * 
 * PLAYER_UNIT:	Entered after the player selects a ready-to-activate player-
 * 				controlled unit. Places some restrictions on mapCursor movement
 * 				(cannot use held movement to exit the unit's movement range) and
 * 				displays range/movement path information to the user.
 * 
 * OTHER_UNIT:	Entered after the player selects a non-player controlled unit.
 * 				Displays the movement & attack range of the selected unit and
 * 				not much else.
 * 				
 * UNIT_MENU:	Entered after the player selects a valid empty movement tile while
 * 				in the PLAYER_UNIT state. Displays a list of actions available to
 * 				the unit based on that unit's inventory, location, nearby enemies or
 * 				allies, and other factors.
 * 
 * MAP_MENU:	Entered after the player presses confirm on an empty or non-active
 * 				player unit tile while in the FREE_MOVE state. Displays a list of
 * 				general/system options for player to choose from.
 * 
 * UNIT_INFO:	Entered after the player presses the info button while over any unit
 * 				while in the FREE_MOVE, PLAYER_UNIT, or OTHER_UNIT states. Allows the
 * 				player to view all available information about the chosen unit as well
 * 				as cycle through other units on the smae team to view their information.
 * 
 * ENEMY_TURN:	Entered after all player units are no longer active, or when the player
 * 				manually chooses to end their turn through an option in the map menu.
 * 				Most player interaction is disabled during this state. Will eventually
 * 				return to the FREE_MOVE state when the enemy turn ends.
 * 
 * @author Samuel Bumgardner
 */
enum PlayerControlStates 
{
	FREE_MOVE;
	PLAYER_UNIT;
	OTHER_UNIT;
	UNIT_MENU;
	MAP_MENU;
	UNIT_INFO;
	ENEMY_TURN;
}