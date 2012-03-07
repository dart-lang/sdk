
class _IDBIndexImpl implements IDBIndex native "*IDBIndex" {

  final String keyPath;

  final bool multiEntry;

  final String name;

  final _IDBObjectStoreImpl objectStore;

  final bool unique;

  _IDBRequestImpl count([var key_OR_range = null]) native;

  _IDBRequestImpl getObject(_IDBKeyImpl key) native;

  _IDBRequestImpl getKey(_IDBKeyImpl key) native;

  _IDBRequestImpl openCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;

  _IDBRequestImpl openKeyCursor([_IDBKeyRangeImpl range = null, int direction = null]) native;
}
