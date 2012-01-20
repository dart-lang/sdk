
class IDBIndex native "*IDBIndex" {

  String get keyPath() native "return this.keyPath;";

  bool get multiEntry() native "return this.multiEntry;";

  String get name() native "return this.name;";

  IDBObjectStore get objectStore() native "return this.objectStore;";

  bool get unique() native "return this.unique;";

  IDBRequest count([IDBKeyRange range = null]) native;

  IDBRequest getObject(IDBKey key) native;

  IDBRequest getKey(IDBKey key) native;

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) native;

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
