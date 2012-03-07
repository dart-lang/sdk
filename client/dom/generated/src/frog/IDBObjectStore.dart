
class _IDBObjectStoreJs extends _DOMTypeJs implements IDBObjectStore native "*IDBObjectStore" {

  final List<String> indexNames;

  final String keyPath;

  final String name;

  final _IDBTransactionJs transaction;

  _IDBRequestJs add(Dynamic value, [_IDBKeyJs key = null]) native;

  _IDBRequestJs clear() native;

  _IDBRequestJs count([var key_OR_range = null]) native;

  _IDBIndexJs createIndex(String name, String keyPath) native;

  _IDBRequestJs delete(var key_OR_keyRange) native;

  void deleteIndex(String name) native;

  _IDBRequestJs getObject(_IDBKeyJs key) native '''return this.get(key);''';

  _IDBIndexJs index(String name) native;

  _IDBRequestJs openCursor([_IDBKeyRangeJs range = null, int direction = null]) native;

  _IDBRequestJs put(Dynamic value, [_IDBKeyJs key = null]) native;
}
