package missions.managers;

import flixel.FlxG;
import flixel.group.FlxGroup;
import menus.cursorMenus.BasicMenu;
import menus.cursorMenus.CursorMenuTemplate;
import menus.MenuTemplate;
import menus.MissionMenuCreator;
import menus.MissionMenuTypes;
import menus.cursorMenus.ResizableBasicMenu;
import missions.MissionState;
import observerPattern.Observed;
import observerPattern.Observer;
import observerPattern.eventSystem.EventTypes;
import observerPattern.eventSystem.InputEvent;
import utilities.PossiblePosTracker;

using observerPattern.eventSystem.EventExtender;

/**
 * A component of MissionState that acts as a middleman between MissionState 
 * 	and various Menu-Template inheriting objects to reduce the complexity of 
 * 	MissionState's code.
 * 
 * @author Samuel Bumgardner
 */
class MenuManager implements Observer
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * The MissionState object that created this manager.
	 * Its functions are used when the MenuManager needs to interact with non-menu parts
	 * 	of the game.
	 */
	private var parentState:MissionState;
	
	
	/**
	 * Menu used when player presses "confirm" button over an empty tile.
	 */
	private var mapActionMenu:BasicMenu;
	
	/**
	 * Menu used when player presses "confirm" button over one of their units.
	 */
	private var unitActionMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to display unit inventory menu.
	 */
	private var unitInvMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select how to interact with an item in a unit's inventory.
	 */
	private var itemActionMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which other unit to trade with.
	 */
	private var tradeTargetMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to trade items between two units.
	 */
	private var tradeActionMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which weapon to use in combat.
	 */
	private var weaponSelectMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which enemy unit to attack.
	 */
	private var attackTargetMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which allied unit to heal.
	 */
	private var healTargetMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which allied unit to rescue.
	 */
	private var rescueTargetMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select which rescued unit to take.
	 */
	private var takeTargetMenu:ResizableBasicMenu;
	
	/**
	 * Menu used to select where to drop a rescued unit.
	 */
	private var dropTargetMenu:ResizableBasicMenu;
	
	/**
	 * X and Y coordinates that "root" level menus (unitAction & mapAction) should use to set 
	 * 	its position when appearing in different regions of the screen.
	 */
	private var rootMenuPos:PossiblePosTracker;
	
	/**
	 * X and Y coordinates that "corner" menus (most non-root menus) should use to set its 
	 * 	position when appearing in different regions of the screen.
	 */
	private var cornerMenuPos:PossiblePosTracker;
	
	
	/**
	 * Tracks what horizontal position menus are currently in.
	 */
	private var menusOnLeft:Bool = true;
	
	/**
	 * Tracks what vertical position menus are currently in.
	 */
	private var menusOnTop:Bool = true;
	
	/**
	 * FlxGroup that holds all HaxeFlixel-inheriting components created by this manager.
	 */
	public var totalFlxGrp(default, null):FlxGroup = new FlxGroup();
	
	/**
	 * Array used to track which menus are currently open.
	 * Allows the player to step backward through the menus, so backing out of one doesn't
	 * 	kick them all the way back to moving the MapCursor again.
	 */
	private var activeMenuStack:Array<MenuTemplate> = new Array<MenuTemplate>();
	
	/**
	 * Array containing al functions that may need to be called as a result of the "cancel"
	 * 	input being pressed inside of a menu.
	 * 
	 * Each menu has one cancel function, so a single array is all that is needed.
	 * 
	 * The order of functions in this array matches the order of the menus inside the
	 * 	MissionMenuTypes enum.
	 */
	private var cancelFunctions:Array<Void->Void> = new Array<Void->Void>();
	
	/**
	 * 2-D array containing all functions that need to be called as a result of a menu
	 * 	option being selected.
	 * 
	 * Some menus with multiple options need different behavior depending on which option
	 * 	was selected, so a 2-D array is used here.
	 * 
	 * The first index should be entry from the MissionMenuTypes enum, and the second index
	 * 	should be an entry from that menu's "*MenuOptions" enum.
	 */
	private var confirmFunctions:Array<Array<Void->Void>> = new Array<Array<Void->Void>>();
	
	/**
	 * Array containing al functions that may need to be called as a result of the "omfp"
	 * 	input being pressed inside of a menu.
	 * 
	 * Each menu has (at most) one info function, so a single array is all that is needed.
	 * 
	 * The order of functions in this array matches the order of the menus inside the
	 * 	MissionMenuTypes enum.
	 */
	private var infoFunctions:Array<Array<Void->Void>> = new Array<Array<Void->Void>>();
	
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer
	 * @param	parent	The MissionState object that created this MenuManager.
	 */
	public function new(parent:MissionState) 
	{
		parentState = parent;
		
		initPossiblePos();
		initMenus();
		fillTotalFlxGrp();
		
		initFunctionArrays();
	}
	
	/**
	 * Create and give appropriate values to all PossiblePosTracker objects.
	 */
	private function initPossiblePos():Void
	{
		rootMenuPos  = new PossiblePosTracker(30, FlxG.width - 30, 60, FlxG.height - 60);
		cornerMenuPos = new PossiblePosTracker(15, FlxG.width - 15, 15, FlxG.height - 15);
	}
	
	/**
	 * Creates all menu objects and adds itself as an observer to each of them.
	 * 
	 * Must be done after initPossiblePos(), otherwise it'll crash when trying to use the
	 * 	possiblePositionTracker objects.
	 * 
	 * NOTE: 
	 * 	If a menu is created but its subject's addObserver() function isn ot properly called,
	 * 		it will not respond to any input. Be careful of that.
	 * 
	 * May try rewriting all of this business later. I'd rather have something that looks cleaner,
	 * 	maybe using a loop to initialize things, or giving the MissionMenuCreator a function to
	 * 	initialize all of the mission menus.
	 */
	private function initMenus():Void
	{
		mapActionMenu = MissionMenuCreator.makeMapActionMenu(rootMenuPos.leftX,
			rootMenuPos.topY, MissionMenuTypes.MAP_ACTION);
		mapActionMenu.subject.addObserver(this);
		
		unitActionMenu = MissionMenuCreator.makeUnitActionMenu(rootMenuPos.leftX, 
			rootMenuPos.topY, MissionMenuTypes.UNIT_ACTION);
		unitActionMenu.subject.addObserver(this);
		
		unitInvMenu = MissionMenuCreator.makeInventoryMenu(0, 0, MissionMenuTypes.UNIT_INVENTORY);
		unitInvMenu.subject.addObserver(this);
		
		itemActionMenu = MissionMenuCreator.makeItemActionMenu(0, 
			0, MissionMenuTypes.ITEM_ACTION);
		itemActionMenu.subject.addObserver(this);
		
		tradeTargetMenu = MissionMenuCreator.makeTradeTargetMenu(cornerMenuPos.leftX, 
			cornerMenuPos.topY, MissionMenuTypes.TRADE_TARGET);
		tradeTargetMenu.subject.addObserver(this);
		
		tradeActionMenu = MissionMenuCreator.makeTradeActionMenu(0, 0, 
			MissionMenuTypes.TRADE_ACTION);
		tradeActionMenu.subject.addObserver(this);
		
		weaponSelectMenu = MissionMenuCreator.makeWeaponSelectMenu(0, 0, 
			MissionMenuTypes.WEAPON_SELECT);
		weaponSelectMenu.subject.addObserver(this);
		
		attackTargetMenu = MissionMenuCreator.makeAttackTargetMenu(cornerMenuPos.leftX,
			cornerMenuPos.topY, MissionMenuTypes.ATTACK_TARGET);
		attackTargetMenu.subject.addObserver(this);
		
		healTargetMenu = MissionMenuCreator.makeHealTargetMenu(cornerMenuPos.leftX,
			cornerMenuPos.topY, MissionMenuTypes.HEAL_TARGET);
		healTargetMenu.subject.addObserver(this);
		
		rescueTargetMenu = MissionMenuCreator.makeRescueTargetMenu(cornerMenuPos.leftX,
			cornerMenuPos.topY, MissionMenuTypes.RESCUE_TARGET);
		rescueTargetMenu.subject.addObserver(this);
		
		takeTargetMenu = MissionMenuCreator.makeTakeTargetMenu(cornerMenuPos.leftX,
			cornerMenuPos.topY, MissionMenuTypes.TAKE_TARGET);
		takeTargetMenu.subject.addObserver(this);
		
		dropTargetMenu = MissionMenuCreator.makeDropTargetMenu(cornerMenuPos.leftX,
			cornerMenuPos.topY, MissionMenuTypes.DROP_TARGET);
		dropTargetMenu.subject.addObserver(this);
	}
	
	/**
	 * Adds all menu objects to the totalFlxGrp in the correct order.
	 * 
	 * May also try rewriting this if I store all of the menu objects in an array later.
	 */
	private function fillTotalFlxGrp():Void
	{
		totalFlxGrp.add(mapActionMenu.totalFlxGrp);
		totalFlxGrp.add(unitActionMenu.totalFlxGrp);
		totalFlxGrp.add(unitInvMenu.totalFlxGrp);
		totalFlxGrp.add(itemActionMenu.totalFlxGrp);
		totalFlxGrp.add(tradeTargetMenu.totalFlxGrp);
		totalFlxGrp.add(tradeActionMenu.totalFlxGrp);
		totalFlxGrp.add(weaponSelectMenu.totalFlxGrp);
		totalFlxGrp.add(attackTargetMenu.totalFlxGrp);
		totalFlxGrp.add(healTargetMenu.totalFlxGrp);
		totalFlxGrp.add(rescueTargetMenu.totalFlxGrp);
		totalFlxGrp.add(takeTargetMenu.totalFlxGrp);
		totalFlxGrp.add(dropTargetMenu.totalFlxGrp);
	}
	
	/**
	 * Initializes cancel, confirm, and info function arrays.
	 */
	private function initFunctionArrays():Void
	{
		// Initial setup
		for (i in 0...MissionMenuTypes.NUM_OF_MENUS)
		{
			cancelFunctions.push(popCancel);
			confirmFunctions.push(new Array<Void->Void>());
		}
		
		// non-default cancel functions
		cancelFunctions[MissionMenuTypes.UNIT_ACTION] = unitActionMenuCancel;
		cancelFunctions[MissionMenuTypes.TRADE_TARGET] = tradeMenuCancel;
		cancelFunctions[MissionMenuTypes.TRADE_ACTION] = tradeMenuCancel;
		
		// confirm function setup.
		
		// Map action confirm setup
		
		confirmFunctions[MissionMenuTypes.MAP_ACTION].push(unitConfirm);
		confirmFunctions[MissionMenuTypes.MAP_ACTION].push(statusConfirm);
		confirmFunctions[MissionMenuTypes.MAP_ACTION].push(optionsConfirm);
		confirmFunctions[MissionMenuTypes.MAP_ACTION].push(suspendConfirm);
		confirmFunctions[MissionMenuTypes.MAP_ACTION].push(endConfirm);
		
		
		// unit action menu
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(attackConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(healConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(talkConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(rescueConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(takeConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(dropConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(itemConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(tradeConfirm);
		confirmFunctions[MissionMenuTypes.UNIT_ACTION].push(waitConfirm);
		
		// item action menu setup
		
		confirmFunctions[MissionMenuTypes.ITEM_ACTION].push(itemEquipConfirm);
		confirmFunctions[MissionMenuTypes.ITEM_ACTION].push(itemUseConfirm);
		confirmFunctions[MissionMenuTypes.ITEM_ACTION].push(itemTradeConfirm);
		confirmFunctions[MissionMenuTypes.ITEM_ACTION].push(itemDiscardConfirm);
		
		// other menu confirm functions
		
		confirmFunctions[MissionMenuTypes.UNIT_INVENTORY].push(unitInvConfirm);
		confirmFunctions[MissionMenuTypes.TRADE_TARGET].push(tradeTargetConfirm);
		confirmFunctions[MissionMenuTypes.TRADE_ACTION].push(tradeActionConfirm);
		confirmFunctions[MissionMenuTypes.WEAPON_SELECT].push(weaponSelectConfirm);
		confirmFunctions[MissionMenuTypes.ATTACK_TARGET].push(attackTargetConfirm);
		confirmFunctions[MissionMenuTypes.HEAL_TARGET].push(healTargetConfirm);
		confirmFunctions[MissionMenuTypes.RESCUE_TARGET].push(rescueTargetConfirm);
		confirmFunctions[MissionMenuTypes.TAKE_TARGET].push(takeTargetConfirm);
		confirmFunctions[MissionMenuTypes.DROP_TARGET].push(dropTargetConfirm);
	}
	
	
	///////////////////////////////////////
	//      MENU STACK MANIPULATION      //
	///////////////////////////////////////
	
	/**
	 * 
	 * pushes the specified menu onto the menu stack. If menu stack was previously empty,
	 * 	calls parentState's firstMenuOpened().
	 * @param	newActiveMenu
	 */
	private function pushMenuStack(newActiveMenu:MenuTemplate):Void
	{
		activeMenuStack.push(newActiveMenu);
		
		if (activeMenuStack.length == 1)
		{
			parentState.firstMenuOpened(newActiveMenu);
		}
		else
		{
			activeMenuStack[activeMenuStack.length - 2].deactivate();
		}
		activateTopMenu();
	}
	
	/**
	 * Removes the top entry from the menustack, and reveals the new top menu.
	 */
	private function popMenuStack():Void
	{
		var menuToDeactivate:MenuTemplate = activeMenuStack.pop();
		menuToDeactivate.deactivate();
		menuToDeactivate.hide();
		
		if (activeMenuStack.length != 0)
		{
			activateTopMenu();
		}
		else
		{
			// May need to adjust parameters later.
			parentState.allMenusClosed(true);
		}
	}
	
	/**
	 * Removes menus from the activeMenuStack until a menu with the requested ID is on top,
	 * 	or the stack is empty.
	 * 
	 * Only calls activateTopMenu on the menu that is left on top, unless the stack is empty.
	 * 
	 * If the a menu with the requested ID is already at the top of the stack, 
	 * 	then no menus will be removed. The top menu will still be activated though.
	 * 
	 * @param	idToStopAt	The menu ID that should be checked for.
	 */
	private function popMenusUntilID(idToStopAt:Int):Void
	{
		while (activeMenuStack.length > 0 &&
			activeMenuStack[activeMenuStack.length - 1].subject.ID != idToStopAt)
		{
			var menuToDeactivate:MenuTemplate = activeMenuStack.pop();
			menuToDeactivate.deactivate();
			menuToDeactivate.hide();
		}
		
		if (activeMenuStack.length != 0)
		{
			activateTopMenu();
		}
		else
		{
			// may need to adjust parameter later.
			parentState.allMenusClosed(false);
		}
	}
	
	/**
	 * Clears the entire menu stack.
	 */
	private function clearMenuStack():Void
	{
		while (activeMenuStack.length > 0)
		{
			var menuToDeactivate:MenuTemplate = activeMenuStack.pop();
			menuToDeactivate.deactivate();
			menuToDeactivate.hide();
		}
		// may need to adjust parameters later.
		parentState.allMenusClosed(false);
	}
	
	/**
	 * Reactivates the active & visible boolean values of the menu at the top of the stack.
	 * 
	 * May also need to expand functionality to have the menu update itself, if that's necessary.
	 */
	private function activateTopMenu():Void
	{
		var menuToActivate:MenuTemplate = activeMenuStack[activeMenuStack.length - 1];
		menuToActivate.activate();
		menuToActivate.reveal();
		
		parentState.changeCurrUpdatingObj(menuToActivate);
	}
	
	/**
	 * Hides all menus in the activeMenuStack.
	 */
	private function hideMenuStack():Void
	{
		for (menu in activeMenuStack)
		{
			menu.hide();
		}
	}
	
	/**
	 * Reveals menus from the top of the stack down, up to and including the first
	 * 	menu with the specified ID.
	 */
	private function revealMenusToID(lastID:Int):Void
	{
		// Reveal all menus up to the "lastID"
		var i:Int = 0;
		var lastIndex:Int = activeMenuStack.length - 1;
		while (i != lastIndex &&
			activeMenuStack[lastIndex- i].subject.ID != lastID)
		{
			activeMenuStack[activeMenuStack.length - 1 - i].reveal();
			i++;
		}
		
		// Reveal the menu with the searched for ID, or the bottom menu in the stack.
		activeMenuStack[activeMenuStack.length - 1 - i].reveal();
	}
	
	
	///////////////////////////////////////
	//       MENU CONFIRM FUNCTIONS      //
	///////////////////////////////////////
	
	// mapActionMenu confirm functions //
	
	/**
	 * Called when mapActionMenu's confirm MenuOption is selected.
	 */
	private function unitConfirm():Void
	{
		trace("Looking at units...");
		popMenuStack();
	}
	
	/**
	 * Called when mapActionMenu's status MenuOption is selected.
	 */
	private function statusConfirm():Void
	{
		trace("Looking at status...");
		popMenuStack();
	}
	
	/**
	 * Called when mapActionMenu's options MenuOption is selected.
	 */
	private function optionsConfirm():Void
	{
		trace("Looking at options...");
		popMenuStack();
	}
	
	/**
	 * Called when mapActionMenu's suspend MenuOption is selected.
	 */
	private function suspendConfirm():Void
	{
		trace("Suspending game...");
		popMenuStack();
	}
	
	/**
	 * Called when mapActionMenu's end MenuOption is selected.
	 */
	private function endConfirm():Void
	{
		trace("ending turn...");
		popMenuStack();
	}
	
	
	// unitActionMenu confirm functions //
	
	/**
	 * Called when unitActionMenu's attack MenuOption is selected.
	 */
	private function attackConfirm():Void
	{
		trace("Attack!");
		hideMenuStack();
		pushMenuStack(weaponSelectMenu);
	}
	
	/**
	 * Called when unitActionMenu's heal MenuOption is selected.
	 */
	private function healConfirm():Void
	{
		trace("Heal!");
		hideMenuStack();
		pushMenuStack(healTargetMenu);
	}
	
	/**
	 * Called when unitActionMenu's talk MenuOption is selected.
	 */
	private function talkConfirm():Void
	{
		trace("Talk!");
		clearMenuStack();
	}
	
	/**
	 * Called when unitActionMenu's rescue MenuOption is selected.
	 */
	private function rescueConfirm():Void
	{
		trace("Resucue!");
		hideMenuStack();
		pushMenuStack(rescueTargetMenu);
	}
	
	/**
	 * Called when unitActionMenu's take MenuOption is selected.
	 */
	private function takeConfirm():Void
	{
		trace("Take!");
		hideMenuStack();
		pushMenuStack(takeTargetMenu);
	}
	
	/**
	 * Called when unitActionMenu's drop MenuOption is selected.
	 */
	private function dropConfirm():Void
	{
		trace("Drop!");
		hideMenuStack();
		pushMenuStack(dropTargetMenu);
	}
	
	/**
	 * Called when unitActionMenu's item MenuOption is selected.
	 */
	private function itemConfirm():Void
	{
		trace("Item!");
		hideMenuStack();
		pushMenuStack(unitInvMenu);
	}
	
	/**
	 * Called when unitActionMenu's trade MenuOption is selected.
	 */
	private function tradeConfirm():Void
	{
		trace("Trade!");
		hideMenuStack();
		pushMenuStack(tradeTargetMenu);
	}
	
	/**
	 * Called when unitActionMenu's wait MenuOption is selected.
	 */
	private function waitConfirm():Void
	{
		trace("Wait!");
		// TEMP code, may go back to pop later.
		clearMenuStack();
	}
	
	
	// unitInvMenu confirm function //
	
	/**
	 * Called when any option in the unitInvMenu is selected.
	 */
	private function unitInvConfirm():Void
	{
		trace("Selected an item...");
		//Set item action menu position here.
		pushMenuStack(itemActionMenu);
	}
	
	
	// itemActionMenu confirm functions //
	
	/**
	 * Called when itemActionMenu's equip MenuOption is selected.
	 */
	private function itemEquipConfirm():Void
	{
		trace("Changing equipped item!");
		popMenuStack();
	}
	
	/**
	 * Called when itemActionMenu's use MenuOption is selected.
	 */
	private function itemUseConfirm():Void
	{
		trace("Using Item");
		// Need to do whatever thing is involved with using the item.
		clearMenuStack();
	}
	
	/**
	 * Called when itemActionMenu's trade MenuOption is selected.
	 */
	private function itemTradeConfirm():Void
	{
		trace("Preparing to trade...");
		hideMenuStack();
		pushMenuStack(tradeTargetMenu);
	}
	
	/**
	 * Called when itemActionMenu's discard MenuOption is selected.
	 */
	private function itemDiscardConfirm():Void
	{
		trace("Throwing away item!");
		popMenuStack();
		// Need to call redisplay of menu here.
		// Or exit if items are empty
	}
	
	
	// tradeTargetMenu confirm function //
	
	/**
	 * Called when any option in the tradeTargetMenu is selected.
	 */
	private function tradeTargetConfirm():Void
	{
		trace("Selected trading target...");
		hideMenuStack();
		pushMenuStack(tradeActionMenu);
	}
	
	
	// tradeActionMenu confirm function //
	
	/**
	 * Called when any option in the tradeActionMenu is selected.
	 */
	private function tradeActionConfirm():Void
	{
		trace("Trading around items!");
	}
	
	
	// weaponSelectMenu confirm function //
	
	/**
	 * Called when any option in the weaponSelectMenu is selected.
	 */
	private function weaponSelectConfirm():Void
	{
		trace("Selected weapon...");
		hideMenuStack();
		pushMenuStack(attackTargetMenu);
	}
	
	
	// attackTargetMenu confirm function //
	
	/**
	 * Called when any option in the attackTargetMenu is selected.
	 */
	private function attackTargetConfirm():Void
	{
		trace("Beginning attack!");
		clearMenuStack();
	}
	
	
	// healTargetMenu confirm function //
	
	/**
	 * Called when any option in the healTargetMenu is selected.
	 */
	private function healTargetConfirm():Void
	{
		trace("Healing target!");
		clearMenuStack();
	}
	
	
	// rescueTargetMenu confirm function //
	
	/**
	 * Called when any option in the rescueTargetMenu is selected.
	 */
	private function rescueTargetConfirm():Void
	{
		trace("Rescuing target!");
		clearMenuStack();
	}
	
	
	// takeTargetMenu confirm function
	
	/**
	 * Called when any option in the unitInvMenu is selected.
	 */
	private function takeTargetConfirm():Void
	{
		trace("Taking target!");
		clearMenuStack();
	}
	
	
	// dropTargetMenu confirm function
	
	/**
	 * Called when any option in the unitInvMenu is selected.
	 */
	private function dropTargetConfirm():Void
	{
		trace("Dropping target!");
		clearMenuStack();
	}
	
	
	
	
	
	///////////////////////////////////////
	//       MENU CANCEL FUNCTIONS       //
	///////////////////////////////////////
	
	/**
	 * Pops the top menu off of the activeMenuStack.
	 * Used by menus that have simple closing behavior.
	 */
	private function popCancel():Void
	{
		popMenuStack();
	}
	
	/**
	 * Probably just pop the menu stack, but if unit has move again flag set,
	 * 	it should move and then have the wait action Menu option.
	 * 
	 * Basically, there's more that needs to be done here.
	 */
	private function unitActionMenuCancel():Void
	{
		popMenuStack();
	}
	
	/**
	 * Closes all menus besides the unit action menu.
	 */
	private function tradeMenuCancel():Void
	{
		popMenusUntilID(MissionMenuTypes.UNIT_ACTION);
	}
	
	///////////////////////////////////////
	//        MENU INFO FUNCTIONS        //
	///////////////////////////////////////
	
	/**
	 * Used by menus that do not react to info-type input.
	 */
	private function doNothing():Void{}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Public interface for opening the base-level mission menus.
	 * Should probably only be used to open the action menu or the map menu in most cases.
	 * 
	 * @param	menuType	An entry from the MissionMenuTypes enum, specifying which menu to open.
	 */
	public function openTopLevelMenu(menuType:Int):Void
	{
		var menuToPush:MenuTemplate;
		
		switch menuType
		{
			case MissionMenuTypes.MAP_ACTION: 
			{
				menuToPush = mapActionMenu;
			}
			
			case MissionMenuTypes.UNIT_ACTION: 
			{
				menuToPush = unitActionMenu;
			}
			
			default:
			{
				trace("Attempted to open a non-top level menu. Opening mapActionMenu instead...");
				menuToPush = mapActionMenu;
			}
		}
		
		pushMenuStack(menuToPush);
	}
	
	/**
	 * Public interface for changing the region of the screen that menus appear in.
	 * 
	 * Could be made more elegant by associating each menu with a position object,
	 * 	and grouping all menus in an array of some sort. Then all that needs to be
	 * 	done is iterate through the array and change the position of the current menu.
	 * 
	 * @param goToLeft	Whether the menus should be positioned on left or right side.
	 */
	public function changeMenuXPositions(goToLeft:Bool):Void
	{
		if (goToLeft != menusOnLeft && goToLeft)
		{
			mapActionMenu.setPos(rootMenuPos.leftX, rootMenuPos.topY);
			unitActionMenu.setPos(rootMenuPos.leftX, rootMenuPos.topY);
			
			tradeTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
			attackTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
			healTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
			rescueTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
			takeTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
			dropTargetMenu.setPos(cornerMenuPos.leftX, cornerMenuPos.topY);
		}
		else if (goToLeft != menusOnLeft && !goToLeft)
		{
			unitActionMenu.setPos(rootMenuPos.rightX - unitActionMenu.boxWidth, 
				rootMenuPos.topY);
			mapActionMenu.setPos(rootMenuPos.rightX - mapActionMenu.boxWidth, rootMenuPos.topY);
			
			tradeTargetMenu.setPos(cornerMenuPos.rightX - tradeTargetMenu.boxWidth, 
				cornerMenuPos.topY);
			attackTargetMenu.setPos(cornerMenuPos.rightX - attackTargetMenu.boxWidth, 
				cornerMenuPos.topY);
			healTargetMenu.setPos(cornerMenuPos.rightX - healTargetMenu.boxWidth, 
				cornerMenuPos.topY);
			rescueTargetMenu.setPos(cornerMenuPos.rightX - rescueTargetMenu.boxWidth, 
				cornerMenuPos.topY);
			takeTargetMenu.setPos(cornerMenuPos.rightX - takeTargetMenu.boxWidth, 
				cornerMenuPos.topY);
			dropTargetMenu.setPos(cornerMenuPos.rightX - dropTargetMenu.boxWidth, 
				cornerMenuPos.topY);
		}
		
		menusOnLeft = goToLeft;
	}
	
	/**
	 * Function to satisfy the Observer interface.
	 * Recieves & responds to notifications from MenuTemplate-type objects.
	 * 
	 * First, it determines what sort of input triggered the event. 
	 * Then, it uses the notifier's ID (and sometimes the menu's selected MenuOption's ID)
	 * 	as index(es) to this MenuManager's cancel, confirm, or infoFunction array. 
	 * 
	 * The selected function is called, executing whatever behavior should occur in response
	 * 	to the notified event.
	 * 
	 * As of right now, responses to info-input events have not been implemented.
	 * 
	 * @param	event		Contains information about what sort of event ocurred.
	 * @param	notifier	The object that detected the event and sent the notification.
	 */
	public function onNotify(event:InputEvent, notifier:Observed):Void 
	{
		switch event.getType()
		{
			case EventTypes.CANCEL:
			{
				var menu:MenuTemplate = cast notifier;
				cancelFunctions[menu.subject.ID]();
			}
			case EventTypes.CONFIRM:
			{
				var menu:MenuTemplate = cast notifier;
				// At the moment, only cursor-type menus have multiple confirm functions.
				if (confirmFunctions[menu.subject.ID].length > 1)
				{
					var cursorMenu:CursorMenuTemplate = cast menu;
					confirmFunctions[cursorMenu.subject.ID][cursorMenu.currMenuOption.id]();
				}
				else
				{
					confirmFunctions[menu.subject.ID][0]();
				}
			}
			case EventTypes.INFO:
			{
				var menu:MenuTemplate = cast notifier;
				//infoFunctions[menu.subject.ID][menu.currMenuOption.id]();
			}
		}
	}
	
}