
class _IDBObjectStoreImpl implements IDBObjectStore native "*IDBObjectStore" {

  final List<String> indexNames;

  final String keyPath;

  final String name;

  final _IDBTransactionImpl transaction;

  _IDBRequestImpl add(Dynamic value, [_IDBKeyImpl key = null]) native;

  _IDBRequestImpl clear() native;

  _IDBRequestImpl count([_IDBKeyRangeImpl range = null]) native;

  _IDBIndexImpl createIndex(String name, String keyPath) native;

  _IDBRequestImpl delete(var key_OR_keyRange) native;

  void deleteIndex(String name) native;

  _IDBRequestImpl getObject(_IDBKeyImpl key) native;

  _IDBIndexImpl index(String name) native;

  _IDBRequestImpl openCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;

  _IDBRequestImpl put(Dynamic value, [_IDBKeyImpl key = null]) native;
}
