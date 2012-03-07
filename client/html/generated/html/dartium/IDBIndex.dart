
class _IDBIndexImpl extends _DOMTypeBase implements IDBIndex {
  _IDBIndexImpl._wrap(ptr) : super._wrap(ptr);

  String get keyPath() => _wrap(_ptr.keyPath);

  bool get multiEntry() => _wrap(_ptr.multiEntry);

  String get name() => _wrap(_ptr.name);

  IDBObjectStore get objectStore() => _wrap(_ptr.objectStore);

  bool get unique() => _wrap(_ptr.unique);

  IDBRequest count([var key_OR_range = null]) {
    if (key_OR_range === null) {
      return _wrap(_ptr.count());
    } else {
      if (key_OR_range is IDBKeyRange) {
        return _wrap(_ptr.count(_unwrap(key_OR_range)));
      } else {
        if (key_OR_range is IDBKey) {
          return _wrap(_ptr.count(_unwrap(key_OR_range)));
        }
      }
    }
    throw "Incorrect number or type of arguments";
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
