
class _IDBFactoryImpl extends _DOMTypeBase implements IDBFactory {
  _IDBFactoryImpl._wrap(ptr) : super._wrap(ptr);

  int cmp(IDBKey first, IDBKey second) {
    return _wrap(_ptr.cmp(_unwrap(first), _unwrap(second)));
  }

  IDBVersionChangeRequest deleteDatabase(String name) {
    return _wrap(_ptr.deleteDatabase(_unwrap(name)));
  }

  IDBRequest getDatabaseNames() {
    return _wrap(_ptr.getDatabaseNames());
  }

  IDBRequest open(String name) {
    return _wrap(_ptr.open(_unwrap(name)));
  }
}
