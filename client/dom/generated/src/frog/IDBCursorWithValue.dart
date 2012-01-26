
class IDBCursorWithValueJs extends IDBCursorJs implements IDBCursorWithValue native "*IDBCursorWithValue" {

  IDBAnyJs get value() native "return this.value;";
}
