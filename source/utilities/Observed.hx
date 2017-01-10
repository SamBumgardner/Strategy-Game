package utilities;

/**
 * Basic interface for observed objects in the Observer design pattern.
 * The actual functionality of a subject is in the Subject class.
 * This interface just exists so that there is some uniting type for all observed classes
 * 	(having everything that needs subject capabilities inherit from Subject wouldn't exactly 
 * 	be ideal, especially since Haxe doesn't allow multiple inheritance).
 * 
 * @author Samuel Bumgardner
 */
interface Observed 
{
	public var subject:Subject;
}