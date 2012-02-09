
class _IDBDatabaseJs extends _DOMTypeJs implements IDBDatabase native "*IDBDatabase" {

  final String name;

  EventListener onabort;

  EventListener onerror;

  EventListener onversionchange;

  final String version;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  _IDBObjectStoreJs createObjectStore(String name) native;

  void deleteObjectStore(String name) native;

  bool dispatchEvent(_EventJs evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _IDBVersionChangeRequestJs setVersion(String version) native;

  _IDBTransactionJs transaction(String storeName, int mode) native;
}
