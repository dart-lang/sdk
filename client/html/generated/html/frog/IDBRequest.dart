
class _IDBRequestImpl implements IDBRequest native "*IDBRequest" {

  static final int DONE = 2;

  static final int LOADING = 1;

  final int errorCode;

  EventListener onerror;

  EventListener onsuccess;

  final int readyState;

  final _IDBAnyImpl result;

  final _IDBAnyImpl source;

  final _IDBTransactionImpl transaction;

  final String webkitErrorMessage;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
