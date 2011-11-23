
class IDBRequest native "*IDBRequest" {

  int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  int readyState;

  IDBAny result;

  IDBAny source;

  IDBTransaction transaction;

  String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(Event evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
