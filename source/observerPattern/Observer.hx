package observerPattern;

import observerPattern.Observed;
import observerPattern.eventSystem.InputEvent;

/**
 * Basic interface for observers in the Observer design patern.
 * @author Samuel Bumgardner
 */
interface Observer {
	public function onNotify(event:InputEvent, notifier:Observed):Void;
}