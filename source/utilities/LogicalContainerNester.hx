package utilities;

/**
 * @author Samuel Bumgardner
 */
interface LogicalContainerNester extends LogicalContainer
{
	public var nestedContainers(null, null):Array<LogicalContainer>;
}