package menus;

import boxes.ResizeableBox;
import flixel.text.FlxText;
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
 * NOTE:
 * 	reveal() must be called after resizing for the menu to display itself properly.
 * 
 * @author Samuel Bumgardner
 */
class ResizeableBasicMenu extends BasicMenu
{
	/**
	 * Array of label text values that may appear in the resizeable menu.
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
	 * 
	 */
	public var resizeableBox:ResizeableBox;
	
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
	 * Overrides BasicMenu's initVarSizedBox to create a resizeable box instead
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
		
		resizeableBox = new ResizeableBox(X, Y, boxWidth, boxHeight, boxSpriteSheet, 
			cornerSize, backgroundSize);
		
		boxSpriteGrp = resizeableBox.totalFlxGrp;
	}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * 
	 * 
	 * @param	newBoolArray
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
	
	override private function resetMenu():Void
	{
		super.resetMenu();
		
		for (i in numActiveLabels...menuOptionArr.length)
		{
			menuOptionArr[i].hide();
		}
	}
	
	///////////////////////////////////////
	//       RESIZE MENU FUNCTIONS       //
	///////////////////////////////////////
	
	/**
	 * 
	 * @param	newBoolArray
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
	 * 
	 * @return	
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
				
				if (menuOptionArr[menuOptionIndex].label.width > maxTextWidth)
				{
					maxTextWidth = menuOptionArr[menuOptionIndex].label.width;
				}
				
				menuOptionIndex++;
			}
		}
		
		return maxTextWidth;
	}
	
	private function updateOptionNeighbors():Void
	{
		for (i in 0...numActiveLabels)
		{
			// Connect the current menu option and the previous option as neighbors.
			if (i > 0) 
			{
				menuOptionArr[i].upOption = menuOptionArr[i - 1];
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
	
	private function hideInactiveLabels():Void
	{
		for (i in numActiveLabels...menuOptionArr.length)
		{
			menuOptionArr[i].hide();
		}
	}
	
	private function resizeOptionBgHighlights(maxTextWidth:Float):Void
	{
		for (i in 0...numActiveLabels)
		{
			menuOptionArr[i].clipBgHighlight(maxTextWidth);
		}
	}
	
	/**
	 * 
	 * @param	maxTextWidth
	 */
	private function resizeMenuBox(maxTextWidth:Float):Void
	{
		var lastActiveLabel:FlxText = menuOptionArr[numActiveLabels - 1].label;
		boxWidth = cast maxTextWidth + cornerSize * 2;
		boxHeight = cast lastActiveLabel.y + lastActiveLabel.height + cornerSize - y;
		
		resizeableBox.resize(boxWidth, boxHeight);
	}
}