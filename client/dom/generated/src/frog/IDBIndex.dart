
class IDBIndexJs extends DOMTypeJs implements IDBIndex native "*IDBIndex" {

  String get keyPath() native "return this.keyPath;";

  bool get multiEntry() native "return this.multiEntry;";

  String get name() native "return this.name;";

  IDBObjectStoreJs get objectStore() native "return this.objectStore;";

  bool get unique() native "return this.unique;";

  IDBRequestJs count([IDBKeyRangeJs range = null]) native;

  IDBRequestJs getObject(IDBKeyJs key) native;

  IDBRequestJs getKey(IDBKeyJs key) native;

  IDBRequestJs openCursor([IDBKeyRangeJs range = null, int direction = null]) native;

  IDBRequestJs openKeyCursor([IDBKeyRangeJs range = null, int direction = null]) native;
}
