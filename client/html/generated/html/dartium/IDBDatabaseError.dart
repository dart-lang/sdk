
class _IDBDatabaseErrorImpl extends _DOMTypeBase implements IDBDatabaseError {
  _IDBDatabaseErrorImpl._wrap(ptr) : super._wrap(ptr);

  int get code() => _wrap(_ptr.code);

  void set code(int value) { _ptr.code = _unwrap(value); }

  String get message() => _wrap(_ptr.message);

  void set message(String value) { _ptr.message = _unwrap(value); }
}
