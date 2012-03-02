
class _IDBCursorWithValueImpl extends _IDBCursorImpl implements IDBCursorWithValue {
  _IDBCursorWithValueImpl._wrap(ptr) : super._wrap(ptr);

  IDBAny get value() => _wrap(_ptr.value);
}
