
class IDBCursorWithValueJS extends IDBCursorJS implements IDBCursorWithValue native "*IDBCursorWithValue" {

  IDBAnyJS get value() native "return this.value;";
}
