
class _EventTargetJs extends _DOMTypeJs implements EventTarget native "*EventTarget" {

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs event) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
