
class EventSource native "EventSource" {

  String URL;

  EventListener onerror;

  EventListener onmessage;

  EventListener onopen;

  int readyState;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
