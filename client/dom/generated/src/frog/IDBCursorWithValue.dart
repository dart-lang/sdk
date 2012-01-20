
class IDBCursorWithValue extends IDBCursor native "*IDBCursorWithValue" {

  IDBAny get value() native "return this.value;";
}
