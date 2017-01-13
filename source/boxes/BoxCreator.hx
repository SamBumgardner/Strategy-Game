package boxes;

import flash.geom.Point;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxColor;
import openfl.Assets;

/**
 * A static class for generating boxes of variable size using a small pallet of graphical
 * 	components.
 * 
 * 	General execution follows this pattern of logic:
 * 		- External code calls setBoxType, which sets up the graphical data.
 * 		- External code calls createBox, which uses the graphical data to create & return 
 * 			an FlxSprite of the desired dimensions.
 * 		- External code may call clearBoxType to clear variables holding the graphical data.
 * 
 *	Graphic data setup follows this pattern of logic:
 * 		- Ensure that the graphical data is not already set up.
 * 		- Use parameters to change simple variables.
 * 		- Clean up old graphics data...
 * 			- Done by destroying the old collection of frames
 * 		- Set up new graphics data...
 * 			- Create a new collection of frames.
 * 			- Break the new box spritesheet into frames, one for each of the following components:
 * 				- Corner
 * 				- Horizontal border
 * 				- Vertical border
 * 				- Background image
 * 
 * 	Box creation follows this pattern of logic:
 * 		- Create a blank sprite of the size specified by the parameters.
 * 		- Starting just inside the top left border, paint the background frame across
 * 			the rest of the box.
 * 		- Paint the horizontal border frame along the top and bottom sides of the box,
 * 			flipping the Y values of the frame when painting along the bottom.
 * 		- Paint the vertical border frame across the left and right sides of the box,
 * 			flipping the X values of the frame when painting along the right side.
 * 		- Paint the corner frame at each of the corners of the box.
 * 
 * 
 * Specification for box spritesheet graphics:
 * 	- In the top-left corner of the graphic, there should be a square image (of any size)
 * 		to be used for all four corners of the box. (Note: will be reflected, not rotated).
 * 	- To the immediate right of the corner graphic, there should be a square image (that is 
 * 		the same size as the corner) for the horizontal border, i.e. the border that runs 
 * 		along the top and bottom of the box.
 * 	- Immediately below the corner graphic, there should be another square image (also the
 * 		same size as the corner) for the vertical border, i.e. the border that runs along
 * 		the right and left sides of the box.
 * 	- Diagonally adjacent to the corner graphic, there should be a square image of any size
 * 		(not necessarily the same size as the other squares) which will be used as a repeating
 * 		background image in the bocy of the box.
 * 	
 * 	NOTE: The side length of the corner/border square and the side length of the background
 * 			square are needed to call the setup function in this class, so keeping track of
 * 			those will be extra helpful.
 * 
 * @author Samuel Bumgardner
 */
class BoxCreator
{
	///////////////////////////////////////
	//         DATA  DECLARATION         //
	///////////////////////////////////////
	
	/**
	 * Collection of FlxFrame objects used to paint the blank sprite of a newly created box.
	 * 
	 * Set up/changed in setBoxType() and clearBoxType, and used in createBox().
	 */
	private static var boxFrames:FlxFramesCollection;
	
	private static var cornerFrame:FlxFrame;
	private static var vertBorderFrame:FlxFrame;
	private static var horizBorderFrame:FlxFrame;
	private static var bgFrame:FlxFrame;
	
	/**
	 * Path to the graphic that the current set of frames was built from.
	 * 
	 * Used to identify if the graphic is already set up or not when setBoxType() is called.
	 */
	private static var currGraphic:FlxGraphicAsset;
	
	/**
	 * Integers used to track the side length of the frames used to paint new boxes.
	 */
	private static var borderSize:Int = 0;
	private static var bgSize:Int = 0;
	
	
	public function new(){}
	
	
	///////////////////////////////////////
	//         PUBLIC  INTERFACE         //
	///////////////////////////////////////
	
	/**
	 * Takes a box spritesheet (see top for a full specification) and size variables as 
	 * parameters, then uses that data to create a frame for each of the box's
	 * components, i.e. the corner, the vertical and horizontal border, and the box background.
	 * 
	 * These frames are used in the createBox() function, so it is important to call this before
	 * attempting to create a box. The box will still be created if you forget, but it'll use
	 * an obviously incorrect spritesheet to build that box.
	 * 
	 * @param	boxSpriteSheet	Asset path to the new box spritesheet.
	 * @param	cornerSize		The side length of the corner and border graphics (assumed square and uniform size).
	 * @param	backgroundSize	The side length of the background graphic (assumed square).
	 */
	public static function setBoxType(boxSpriteSheet:FlxGraphicAsset, cornerSize:Int, 
		backgroundSize:Int):Void
	{
		// Only run the setup if the parameters specify a new box spritesheet.
		if (currGraphic != boxSpriteSheet)
		{
			// Set new variables
			currGraphic = boxSpriteSheet;
			borderSize = cornerSize;
			bgSize = backgroundSize;
			
			// Clean up old graphics data.
			if (boxFrames != null)
			{	
				boxFrames.destroy();
			}
			
			// Set up new graphics data.
			boxFrames = 
				new FlxFramesCollection(FlxGraphic.fromBitmapData(
					Assets.getBitmapData(currGraphic)));
			
			// NOTE: each frame requires its own FlxRect. Reusing the same one does not work.
			cornerFrame = 
				boxFrames.addSpriteSheetFrame(new FlxRect(0, 0, borderSize, borderSize));
			vertBorderFrame = 
				boxFrames.addSpriteSheetFrame(new FlxRect(0, borderSize, borderSize, borderSize));
			horizBorderFrame = 
				boxFrames.addSpriteSheetFrame(new FlxRect(borderSize, 0, borderSize, borderSize));
			bgFrame = 
				boxFrames.addSpriteSheetFrame(
					new FlxRect(borderSize, borderSize, backgroundSize, backgroundSize));
		}
	}
	
	/**
	 * Clears values from the variables that were set by setBoxType().
	 */
	public static function clearBoxType():Void
	{
		currGraphic = null;
		borderSize = 0;
		bgSize = 0;
		
		if (boxFrames != null)
		{
			boxFrames.destroy();
		}
	}
	
	/**
	 * Creates an FlxSprite of a box using the variables that were set up in setBoxType().
	 * 
	 * Accomplishes this by painting the frames' bitmap data onto the appropriate sections
	 * of the box, flipping the frame in the x and y directions when necessary. 
	 * 
	 * NOTE: the repeated background begins at the right & bottom corner of the top left corner,
	 * 	and repeats until reaching the end of the box. The box's edges are painted on afterward,
	 * 	which covers up any background sprites that continued outside of its background area. This
	 * 	means that the bottom/right edges of the background area may be (and probably will be) 
	 * 	covered up by the bottom and right borders of the box.
	 * 
	 * @param	boxWidth	The desired width of the box in pixels (including borders)
	 * @param	boxHeight	The desired height of the box in pixels (including borders)
	 * @return	The requested box, as a single FlxSprite.
	 */
	public static function createBox(boxWidth:Float, boxHeight:Float):FlxSprite
	{
		if (currGraphic == null)
		{
			trace("Attempted createBox, but currGraphic was not set. Call setBoxType() first.");
			setBoxType(AssetPaths.box_test__png, 15, 15);
		}
		
		// Set up sprite with empty graphic.
		var newSprite:FlxSprite = new FlxSprite();
		newSprite.makeGraphic(cast boxWidth, cast boxHeight, FlxColor.TRANSPARENT);
		
		var targetPoint:Point = new Point();
		
		var rightX:Float = boxWidth - borderSize;
		var	bottomY:Float = boxHeight - borderSize;
		
		// Paint on background frame.
		for (y in 0...(Math.ceil(boxHeight / bgSize) - 1))
		{
			for (x in 0...(Math.ceil(boxWidth / bgSize) - 1))
			{
				targetPoint.setTo(x * bgSize + borderSize, y * bgSize + borderSize);
				bgFrame.paint(newSprite.pixels, targetPoint);
			}
		}
		
		// Paint on horizontal border (top and bottom) frame.
		for (i in 1...(Math.ceil(boxWidth / borderSize) - 1))
		{
			targetPoint.setTo(i * borderSize, 0);
			horizBorderFrame.paint(newSprite.pixels, targetPoint);
			targetPoint.offset(0, bottomY);
			horizBorderFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, false, true);
		}
		
		// Paint on vertical border (left and right) frame.
		for (i in 1...(Math.ceil(boxHeight / borderSize) - 1))
		{
			targetPoint.setTo(0, i * borderSize);
			vertBorderFrame.paint(newSprite.pixels, targetPoint);
			targetPoint.offset(rightX, 0);
			vertBorderFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, true, false);
		}
		
		// Paint on the corner frame four times.
		for (i in 0...2)
		{
			for (j in 0...2)
			{
				targetPoint.setTo(rightX * i, bottomY * j);
				cornerFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0,
					i == 1, j == 1);
			}
		}
		
		return newSprite;
	}
	
	/**
	 * Creates an FlxSprite with the graphic of the bottom edge of a box, corners included.
	 * Useful for resizing boxes, which can overlay these over some section of the box and
	 * 	set up a clipping rectangle to make the box appear to resize at will.
	 * 
	 * @param	width	The desired width of the created edge.
	 * @return	An FlxSprite with the graphic of the bottom edge of a box.
	 */
	public static function createBottomEdge(width:Float):FlxSprite
	{
		if (currGraphic == null)
		{
			trace("Attempted createBottomEdge, but currGraphic was not set. " +
				"Call setBoxType() first.");
			setBoxType(AssetPaths.box_test__png, 15, 15);
		}
		
		// Set up sprite with empty graphic.
		var newSprite:FlxSprite = new FlxSprite();
		newSprite.makeGraphic(cast width, cast borderSize, FlxColor.TRANSPARENT);
		
		var targetPoint:Point = new Point();
		
		// Paint on horizontal border (top and bottom) frame.
		for (i in 1...(Math.ceil(width / borderSize) - 1))
		{
			targetPoint.setTo(i * borderSize, 0);
			horizBorderFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, false, true);
		}
		
		// Paint on the corner frame twice
		var rightX:Float = width - borderSize;
		for (i in 0...2)
		{
			targetPoint.setTo(rightX * i, 0);
			cornerFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, i == 1, true);
		}
		
		return newSprite;
	}
	
	/**
	 * Creates an FlxSprite with the graphic of the right edge of a box, corners included.
	 * Useful for resizing boxes, which can overlay these over some section of the box and
	 * 	set up a clipping rectangle to make the box appear to resize at will.
	 * 
	 * @param	height	The desired height of the created edge.
	 * @return	An FlxSprite with the graphic of the right edge of a box.
	 */
	public static function createRightEdge(height:Float):FlxSprite
	{
		if (currGraphic == null)
		{
			trace("Attempted createRightEdge, but currGraphic was not set. " +
				"Call setBoxType() first.");
			setBoxType(AssetPaths.box_test__png, 15, 15);
		}
		
		// Set up sprite with empty graphic.
		var newSprite:FlxSprite = new FlxSprite();
		newSprite.makeGraphic(cast borderSize, cast height, FlxColor.TRANSPARENT);
		
		var targetPoint:Point = new Point();
		
		// Paint on vertical border (left and right) frame.
		for (i in 1...(Math.ceil(height / borderSize) - 1))
		{
			targetPoint.setTo(0, i * borderSize);
			vertBorderFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, true, false);
		}
		
		// Paint on the corner frame twice.
		var bottomY:Float = height - borderSize;
		for (i in 0...2)
		{
			targetPoint.setTo(0, bottomY * i);
			cornerFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, true, i == 1);
		}
		
		return newSprite;
	}
	
	/**
	 * Creates an FlxSprite with the corner of a box as its graphic.
	 * Useful for resizing boxes, which can overlay this over some section of the box and
	 * 	set up a clipping rectangle to make the box appear to resize at will.
	 * 
	 * @param	flipX	Whether the corner should be flipped in the X direction by default.
	 * @param	flipY	Whether the corner should be flipped in the Y direction by default.
	 * @return	The FlxSprite with the graphic of a corner.
	 */
	public static function createCorner(flipX:Bool, flipY:Bool):FlxSprite
	{
		// Set up sprite with empty graphic.
		var newSprite:FlxSprite = new FlxSprite();
		newSprite.makeGraphic(borderSize, borderSize, FlxColor.TRANSPARENT);
		
		var targetPoint:Point = new Point();
		
		// Paint on the corner frame twice.
		cornerFrame.paintRotatedAndFlipped(newSprite.pixels, targetPoint, 0, flipX, flipY);
		
		return newSprite;
	}
}