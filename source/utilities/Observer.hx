package utilities;

import utilities.InputEvent;

/**
 * Basic interface for observers in the Observer design patern.
 * @author Samuel Bumgardner
 */
interface Observer {
	public function onNotify(event:InputEvent, notifier:Observed):Void;
}