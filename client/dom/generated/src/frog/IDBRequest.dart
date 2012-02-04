
class _IDBRequestJs extends _DOMTypeJs implements IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  final int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  final int readyState;

  final _IDBAnyJs result;

  final _IDBAnyJs source;

  final _IDBTransactionJs transaction;

  final String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
