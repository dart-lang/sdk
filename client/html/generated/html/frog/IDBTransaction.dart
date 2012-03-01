
class _IDBTransactionImpl implements IDBTransaction native "*IDBTransaction" {

  static final int READ_ONLY = 0;

  static final int READ_WRITE = 1;

  static final int VERSION_CHANGE = 2;

  final _IDBDatabaseImpl db;

  final int mode;

  EventListener onabort;

  EventListener oncomplete;

  EventListener onerror;

  void abort() native;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  bool dispatchEvent(_EventImpl evt) native;

  _IDBObjectStoreImpl objectStore(String name) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;
}
