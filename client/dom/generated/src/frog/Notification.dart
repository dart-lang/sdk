
class Notification native "Notification" {

  String dir;

  EventListener onclick;

  EventListener onclose;

  EventListener ondisplay;

  EventListener onerror;

  String replaceId;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void cancel() native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void show() native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
