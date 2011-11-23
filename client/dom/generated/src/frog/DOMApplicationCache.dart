
class DOMApplicationCache native "*DOMApplicationCache" {

  int status;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void swapCache() native;

  void update() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
