
class MessagePort native "MessagePort" {

  EventListener onmessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void postMessage(String message) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void start() native;

  void webkitPostMessage(String message) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
