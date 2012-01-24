
class EventTargetJs extends DOMTypeJs implements EventTarget native "*EventTarget" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
