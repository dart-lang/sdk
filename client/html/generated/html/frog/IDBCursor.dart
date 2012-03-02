
class _IDBCursorImpl implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  final int direction;

  final _IDBKeyImpl key;

  final _IDBKeyImpl primaryKey;

  final _IDBAnyImpl source;

  void continueFunction([_IDBKeyImpl key = null]) native;

  _IDBRequestImpl delete() native;

  _IDBRequestImpl update(Dynamic value) native;
}
