
class WorkerContext native "WorkerContext" {

  WorkerLocation location;

  WorkerNavigator navigator;

  EventListener onerror;

  NotificationCenter webkitNotifications;

  DOMURL webkitURL;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void clearInterval(int handle) native;

  void clearTimeout(int handle) native;

  void close() native;

  bool dispatchEvent(Event evt) native;

  void importScripts() native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  int setInterval(TimeoutHandler handler, int timeout) native;

  int setTimeout(TimeoutHandler handler, int timeout) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
