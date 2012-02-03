
class _IDBCursorJs extends _DOMTypeJs implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  int get direction() native "return this.direction;";

  _IDBKeyJs get key() native "return this.key;";

  _IDBKeyJs get primaryKey() native "return this.primaryKey;";

  _IDBAnyJs get source() native "return this.source;";

  void continueFunction([_IDBKeyJs key = null]) native;

  _IDBRequestJs delete() native;

  _IDBRequestJs update(Dynamic value) native;
}
