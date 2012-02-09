
class _IDBObjectStoreJs extends _DOMTypeJs implements IDBObjectStore native "*IDBObjectStore" {

  final String keyPath;

  final String name;

  final _IDBTransactionJs transaction;

  _IDBRequestJs add(Dynamic value, [_IDBKeyJs key = null]) native;

  _IDBRequestJs clear() native;

  _IDBRequestJs count([_IDBKeyRangeJs range = null]) native;

  _IDBIndexJs createIndex(String name, String keyPath) native;

  _IDBRequestJs delete(_IDBKeyJs key) native;

  void deleteIndex(String name) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native;

  _IDBIndexJs index(String name) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs put(Dynamic value, [_IDBKeyJs key = null]) native;
}
