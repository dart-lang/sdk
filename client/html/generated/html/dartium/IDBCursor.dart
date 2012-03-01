
class _IDBCursorImpl extends _DOMTypeBase implements IDBCursor {
  _IDBCursorImpl._wrap(ptr) : super._wrap(ptr);

  int get direction() => _wrap(_ptr.direction);

  IDBKey get key() => _wrap(_ptr.key);

  IDBKey get primaryKey() => _wrap(_ptr.primaryKey);

  IDBAny get source() => _wrap(_ptr.source);

  void continueFunction([IDBKey key = null]) {
    if (key === null) {
      _ptr.continueFunction();
      return;
    } else {
      _ptr.continueFunction(_unwrap(key));
      return;
    }
  }

  IDBRequest delete() {
    return _wrap(_ptr.delete());
  }

  IDBRequest update(Dynamic value) {
    return _wrap(_ptr.update(_unwrap(value)));
  }
}
