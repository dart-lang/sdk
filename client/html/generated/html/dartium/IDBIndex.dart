
class _IDBIndexImpl extends _DOMTypeBase implements IDBIndex {
  _IDBIndexImpl._wrap(ptr) : super._wrap(ptr);

  String get keyPath() => _wrap(_ptr.keyPath);

  bool get multiEntry() => _wrap(_ptr.multiEntry);

  String get name() => _wrap(_ptr.name);

  IDBObjectStore get objectStore() => _wrap(_ptr.objectStore);

  bool get unique() => _wrap(_ptr.unique);

  IDBRequest count([IDBKeyRange range = null]) {
    if (range === null) {
      return _wrap(_ptr.count());
    } else {
      return _wrap(_ptr.count(_unwrap(range)));
    }
  }

  IDBRequest getObject(IDBKey key) {
    return _wrap(_ptr.getObject(_unwrap(key)));
  }

  IDBRequest getKey(IDBKey key) {
    return _wrap(_ptr.getKey(_unwrap(key)));
  }

  IDBRequest openCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return _wrap(_ptr.openCursor());
      }
    } else {
      if (direction === null) {
        return _wrap(_ptr.openCursor(_unwrap(range)));
      } else {
        return _wrap(_ptr.openCursor(_unwrap(range), _unwrap(direction)));
      }
    }
    throw "Incorrect number or type of arguments";
  }

  IDBRequest openKeyCursor([IDBKeyRange range = null, int direction = null]) {
    if (range === null) {
      if (direction === null) {
        return _wrap(_ptr.openKeyCursor());
      }
    } else {
      if (direction === null) {
        return _wrap(_ptr.openKeyCursor(_unwrap(range)));
      } else {
        return _wrap(_ptr.openKeyCursor(_unwrap(range), _unwrap(direction)));
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
