
class IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

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
