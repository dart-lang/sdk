
class _IDBIndexJs extends _DOMTypeJs implements IDBIndex native "*IDBIndex" {

  String get keyPath() native "return this.keyPath;";

  bool get multiEntry() native "return this.multiEntry;";

  String get name() native "return this.name;";

  _IDBObjectStoreJs get objectStore() native "return this.objectStore;";

  bool get unique() native "return this.unique;";

  _IDBRequestJs count([_IDBKeyRangeJs range = null]) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native;

  _IDBRequestJs getKey(_IDBKeyJs key) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs openKeyCursor([_IDBKeyRangeJs range = null, int direction = null]) native;
}
