
class _IDBIndexJs extends _DOMTypeJs implements IDBIndex native "*IDBIndex" {

  final String keyPath;

  final bool multiEntry;

  final String name;

  final _IDBObjectStoreJs objectStore;

  final bool unique;

  _IDBRequestJs count([_IDBKeyRangeJs range = null]) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native;

  _IDBRequestJs getKey(_IDBKeyJs key) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs openKeyCursor([_IDBKeyRangeJs range = null, int direction = null]) native;
}
