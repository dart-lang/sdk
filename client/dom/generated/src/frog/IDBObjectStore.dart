
class IDBObjectStore native "IDBObjectStore" {

  String keyPath;

  String name;

  IDBRequest add(String value, [IDBKey key = null]) native;

  IDBRequest clear() native;

  IDBIndex createIndex(String name, String keyPath) native;

  IDBRequest delete(IDBKey key) native;

  void deleteIndex(String name) native;

  IDBRequest getObject(IDBKey key) native;

  IDBIndex index(String name) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) native;

  IDBRequest put(String value, [IDBKey key = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
