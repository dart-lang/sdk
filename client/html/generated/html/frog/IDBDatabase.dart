
class _IDBDatabaseImpl implements IDBDatabase native "*IDBDatabase" {

  final String name;

  final List<String> objectStoreNames;

  EventListener onabort;

  EventListener onerror;

  EventListener onversionchange;

  final String version;

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  void close() native;

  _IDBObjectStoreImpl createObjectStore(String name) native;

  void deleteObjectStore(String name) native;

  bool dispatchEvent(_EventImpl evt) native;

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) native;

  _IDBVersionChangeRequestImpl setVersion(String version) native;

  _IDBTransactionImpl transaction(var storeName_OR_storeNames, [int mode = null]) native;
}
