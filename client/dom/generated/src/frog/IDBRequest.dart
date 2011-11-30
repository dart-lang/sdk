
class IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  int errorCode;

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
