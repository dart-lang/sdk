
class IDBCursor native "IDBCursor" {

  int direction;

  IDBKey key;

  IDBKey primaryKey;

  IDBAny source;

  void continueFunction([IDBKey key = null]) native;

  IDBRequest delete() native;

  IDBRequest update(String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
