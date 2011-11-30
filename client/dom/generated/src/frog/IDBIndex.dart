
class IDBIndex native "*IDBIndex" {

  String keyPath;

  String name;

  IDBObjectStore objectStore;

  bool unique;

  IDBRequest getObject(IDBKey key) native;

  IDBRequest getKey(IDBKey key) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) native;

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
