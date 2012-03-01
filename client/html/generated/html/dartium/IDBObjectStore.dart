
class _IDBObjectStoreImpl extends _DOMTypeBase implements IDBObjectStore {
  _IDBObjectStoreImpl._wrap(ptr) : super._wrap(ptr);

  List<String> get indexNames() => _wrap(_ptr.indexNames);

  String get keyPath() => _wrap(_ptr.keyPath);

  String get name() => _wrap(_ptr.name);

  IDBTransaction get transaction() => _wrap(_ptr.transaction);

  IDBRequest add(Dynamic value, [IDBKey key = null]) {
    if (key === null) {
      return _wrap(_ptr.add(_unwrap(value)));
    } else {
      return _wrap(_ptr.add(_unwrap(value), _unwrap(key)));
    }
  }

  IDBRequest clear() {
    return _wrap(_ptr.clear());
  }

  IDBRequest count([IDBKeyRange range = null]) {
    if (range === null) {
      return _wrap(_ptr.count());
    } else {
      return _wrap(_ptr.count(_unwrap(range)));
    }
  }

  IDBIndex createIndex(String name, String keyPath) {
    return _wrap(_ptr.createIndex(_unwrap(name), _unwrap(keyPath)));
  }

  IDBRequest delete(IDBKey key) {
    return _wrap(_ptr.delete(_unwrap(key)));
  }

  void deleteIndex(String name) {
    _ptr.deleteIndex(_unwrap(name));
    return;
  }

  IDBRequest getObject(IDBKey key) {
    return _wrap(_ptr.getObject(_unwrap(key)));
  }

  IDBIndex index(String name) {
    return _wrap(_ptr.index(_unwrap(name)));
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

  IDBRequest put(Dynamic value, [IDBKey key = null]) {
    if (key === null) {
      return _wrap(_ptr.put(_unwrap(value)));
    } else {
      return _wrap(_ptr.put(_unwrap(value), _unwrap(key)));
    }
  }
}
