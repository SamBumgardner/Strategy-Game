package menus.cursorMenus;

import boxes.ResizableBox;
import flixel.text.FlxText;
import menus.cursorMenus.BasicMenu;
import observerPattern.Observed;
import utilities.HideableEntity;
import utilities.UpdatingEntity;

/**
 * A menu that can be dynamically resized (to become smaller) on demand, while still
 * 	remaining performant.
 * 
 * To use, specify all possible menu options at the start.
 * 
 * 
 * After resizing, the visible menu options will have the same id that those menu options
 * 	would have if all were visible. i.e. if the original un-resized menu had 3 options:
 * 		[ "jump", "run", "fight"]
 * 
 * 	and changeMenuOptions() was called with this array of boolean values:
 * 		[ true, false, true]
 * 
 * 	then the menu would only display the "jump" and "fight" options, using the first
 * 	two MenuOption objects in menuOptionArr. However, the ids of those two menu options
 * 	match the ids of the original "jump" and "fight" menu options (which in this case
 * 	would be 0 and 2, respectively).
 * 
 * 	This is nice because when that example menu notifies events, we know that currMenuOption's
 * 	id == 2 means that the "fight" option was selected, regardless of how many options are
 * 	currently displayed in the menu.
 * 
 * NOTE:
 * 	reveal() must be called after resizing for the menu to display itself properly.
 * 
 * @author Samuel Bumgardner
 */
class ResizableBasicMenu extends BasicMenu
{
	/**
	 * Array of label text values that may appear in the resizable menu.
	 * Set during initialization, and shouldn't be altered afterward.
	 */
	public var possibleLabelText(default, null):Array<String>;
	
	/**
	 * Array of boolean values that indicate which menu options should be displayed.
	 */
	public var activeLabels(default, null):Array<Bool>;
	
	/**
	 * The number of options currently displayed in the menu.
	 * Should always match the number of "true" values in the activeLabels array.
	 */
	public var numActiveLabels(default, null):Int;
	
	/**
	 * Object that contains a set of sprites that can be used as a resizable box.
	 * Call this object's public functions to do any resizing or interactions with
	 *  the box.
	 */
	public var resizableBox:ResizableBox;
	
	///////////////////////////////////////
	//          INITIALIZATION           //
	///////////////////////////////////////
	
	/**
	 * Initializer.
	 * 
	 * @param	X				The desired x position of the menu.
	 * @param	Y				The desired y position of the menu.
	 * @param	labelTextArr	Array of strings for all of the menu's possible options.
	 * @param	subjectID		ID used by the menu's Subject component when notifying observers.
	 */
	public function new(X:Float, Y:Float, labelTextArr:Array<String>, ?subjectID:Int = 0) 
	{
		initLabelArrays(labelTextArr);
		numActiveLabels = possibleLabelText.length;
		super(X, Y, labelTextArr, subjectID);
	}
	
	/**
	 * Initializes possibleLabelText and activeLabels arrays.
	 * 
	 * possibleLabelText becomes a deep copy of the passed-in labelTextArr.
	 * 
	 * activeLabels becomes an array of boolean values.
	 * 	Its length is equal to the length of possibleLabelText.
	 * 	All indexes are initially set to true.
	 * 
	 * @param	labelTextArr	Array of strings copied to create possibleLabelText.
	 */
	private function initLabelArrays(labelTextArr:Array<String>):Void
	{
		possibleLabelText = labelTextArr.map(function(s:String){return s;});
		
		activeLabels = new Array<Bool>();
		for (label in possibleLabelText)
		{
			activeLabels.push(true);
		}
	}
	
	/**
	 * Overrides BasicMenu's initVarSizedBox to create a resizable box instead
	 * 	of just an ordinary box. Otherwise follows the same steps and logical
	 * 	structure.
	 * 
	 * @param	X				The desired x position of the menu.
	 * @param	Y				The desired y position of the menu.
	 * @param	maxTextWidth	The width of the largest MenuOption's label.
	 */
	override private function initMenuBox(X:Float, Y:Float, maxTextWidth:Float):Void 
	{
		var lastLabel:FlxText = menuOptionArr[menuOptionArr.length - 1].label;
		boxWidth = cast maxTextWidth + cornerSize * 2;
		boxHeight = cast lastLabel.y + lastLabel.height + cornerSize - Y;
		
		resizableBox = new ResizableBox(X, Y, boxWidth, boxHeight, boxSpriteSheet, 
			cornerSize, backgroundSize);
		
		boxSpriteGrp = resizableBox.totalFlxGrp;
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Public-facing function used to change the menu's active labels.
	 * 
	 * The provided boolean array should match the layout of the possibleLabelText,
	 * 	so an array with values [true, false, true] means that there are two active
	 * 	labels. 
	 * 
	 * They will use the text content from the 0 & 2 indexes of 
	 * 	possibleLabelText and have ids 0 & 2.
	 * 
	 * @param	newBoolArray	Specifies which menu options should be active.
	 */
	public function changeMenuOptions(newBoolArray:Array<Bool>):Void
	{
		setActiveLabels(newBoolArray);
		var maxTextWidth:Float = updateOptionLabelText();
		updateOptionNeighbors();
		hideInactiveLabels();
		resizeOptionBgHighlights(maxTextWidth);
		resizeMenuBox(maxTextWidth);
	}
	
	
	///////////////////////////////////////
	//       MENU TEMPLATE OVERRIDE      //
	///////////////////////////////////////
	
	/**
	 * Helper function for MenuTemplate's reveal().
	 * Also is responsible for resetting the menu's variables and appearance back to their
	 * 	starting states. This includes hiding the background highlight graphic of all menu
	 * 	options that are not initally hovered over in the menu.
	 * 
	 * In ResizableBasicMenu, it must also hide all menuOptions that are not currently
	 * 	active.
	 * 
	 * NOTE: Assumes that there is at least one entry in menuOptionArr.
	 */
	override private function resetMenu():Void
	{
		super.resetMenu();
		
		for (i in numActiveLabels...menuOptionArr.length)
		{
			menuOptionArr[i].hide();
		}
	}
	
	/**
	 * Public function for changing the position of the menu and all of its components.
	 * 
	 * This override adds code to update the ResizableBox's x & y variables too, which
	 * 	would otherwise be ignored because ResizableBox itself is not in the totalFlxGrp.
	 * ResizableBox uses those variables when positioning its components after resizing,
	 * 	leaving them unchanged would lead to some serious problems.
	 * 
	 * @param	newX	The menu's new x value.
	 * @param	newY	The menu's new y value.
	 */
	override public function setPos(newX:Float, newY:Float):Void
	{
		super.setPos(newX, newY);
		resizableBox.x = newX;
		resizableBox.y = newY;
	}
	
	///////////////////////////////////////
	//       RESIZE MENU FUNCTIONS       //
	///////////////////////////////////////
	
	/**
	 * Changes contents of activeLabels array to match the contents of the provided
	 * 	array of booleans.
	 * 
	 * @param	newBoolArray	Array of boolean values that activeLabels should match.
	 */
	private function setActiveLabels(newBoolArray:Array<Bool>):Void
	{
		if (newBoolArray.length != activeLabels.length)
		{
			trace("ERROR: the array provided to setActiveLabels() has an incorrect number " +
				"of elements.");
		}
		else
		{
			numActiveLabels = 0;
			for (i in 0...newBoolArray.length)
			{
				activeLabels[i] = newBoolArray[i];
				
				if (activeLabels[i])
				{
					numActiveLabels++;
				}
			}
		}
	}
	
	/**
	 * Changes the menu's visible options based on the contents of the activeLabelsArray.
	 * 
	 * To accomplish this, the first numActiveLabels MenuOptions change text and ids to 
	 * 	match the labels that are set to be "true" in the activeLabels array. 
	 * 
	 * The MenuOptions not needed to represent the active menu entries are left unchanged,
	 * 	and will not be displayed when the menu is made visible.
	 * 
	 * @return	The width of the widest active label. Needed when resizing the menu box.
	 */
	private function updateOptionLabelText():Float
	{
		var maxTextWidth:Float = 0;
		var menuOptionIndex:Int = 0;
		for (useLabelIndex in 0...activeLabels.length)
		{
			if (activeLabels[useLabelIndex])
			{
				menuOptionArr[menuOptionIndex].label.text = possibleLabelText[useLabelIndex];
				menuOptionArr[menuOptionIndex].id = useLabelIndex;
				
				if (menuOptionArr[menuOptionIndex].label.width > maxTextWidth)
				{
					maxTextWidth = menuOptionArr[menuOptionIndex].label.width;
				}
				
				menuOptionIndex++;
			}
		}
		
		return maxTextWidth;
	}
	
	/**
	 * Changes the MenuOptions' neighbor variables so that all active MenuOptions
	 * 	are linked together in the BasicMenu style: vertically, with the bottom
	 * 	and top options connecting as "wrapped" neighbors.
	 */
	private function updateOptionNeighbors():Void
	{
		for (i in 0...numActiveLabels)
		{
			// Connect the current menu option and the previous option as neighbors.
			if (i > 0) 
			{
				menuOptionArr[i].upOption = menuOptionArr[i - 1];
				menuOptionArr[i].downIsWrap = false;
				menuOptionArr[i - 1].downOption = menuOptionArr[i];
			}
			
			// Connect the last menu option to the first menu option as neighbors.
			if (i == numActiveLabels - 1)
			{
				menuOptionArr[0].upOption = menuOptionArr[i];
				menuOptionArr[0].upIsWrap = true;
				menuOptionArr[i].downOption = menuOptionArr[0];
				menuOptionArr[i].downIsWrap = true;
			}
		}
	}
	
	/**
	 * Hides all inactive labels in the menu.
	 */
	private function hideInactiveLabels():Void
	{
		for (i in numActiveLabels...menuOptionArr.length)
		{
			menuOptionArr[i].hide();
		}
	}
	
	/**
	 * Applies clipping rectangle to all active MenuOption bgHightlights,
	 * 	resizing them to match the width of the widest active label text.
	 * 
	 * @param	maxTextWidth	The width of the menu's widest active label.
	 */
	private function resizeOptionBgHighlights(maxTextWidth:Float):Void
	{
		for (i in 0...numActiveLabels)
		{
			menuOptionArr[i].clipBgHighlight(maxTextWidth);
		}
	}
	
	/**
	 * Resizes the background menu box, selecting height and width values
	 * 	based on the collective hieght of the MenuOptions and the width of the
	 * 	widest MenuOption.
	 * 
	 * @param	maxTextWidth	Width of widest label text in the menu.
	 */
	private function resizeMenuBox(maxTextWidth:Float):Void
	{
		var lastActiveLabel:FlxText = menuOptionArr[numActiveLabels - 1].label;
		boxWidth = cast maxTextWidth + cornerSize * 2;
		boxHeight = cast lastActiveLabel.y + lastActiveLabel.height + cornerSize - y;
		
		resizableBox.resize(boxWidth, boxHeight);
	}
}