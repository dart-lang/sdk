
class IDBCursorJs extends DOMTypeJs implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  int get direction() native "return this.direction;";

  IDBKeyJs get key() native "return this.key;";

  IDBKeyJs get primaryKey() native "return this.primaryKey;";

  IDBAnyJs get source() native "return this.source;";

  void continueFunction([IDBKeyJs key = null]) native;

  IDBRequestJs delete() native;

  IDBRequestJs update(String value) native;
}
