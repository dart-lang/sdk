
class IDBCursorJS implements IDBCursor native "*IDBCursor" {

  static final int NEXT = 0;

  static final int NEXT_NO_DUPLICATE = 1;

  static final int PREV = 2;

  static final int PREV_NO_DUPLICATE = 3;

  int get direction() native "return this.direction;";

  IDBKeyJS get key() native "return this.key;";

  IDBKeyJS get primaryKey() native "return this.primaryKey;";

  IDBAnyJS get source() native "return this.source;";

  void continueFunction([IDBKeyJS key = null]) native;

  IDBRequestJS delete() native;

  IDBRequestJS update(String value) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
