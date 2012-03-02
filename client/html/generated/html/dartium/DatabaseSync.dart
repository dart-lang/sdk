
class _DatabaseSyncImpl extends _DOMTypeBase implements DatabaseSync {
  _DatabaseSyncImpl._wrap(ptr) : super._wrap(ptr);

  String get lastErrorMessage() => _wrap(_ptr.lastErrorMessage);

  String get version() => _wrap(_ptr.version);

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionSyncCallback callback = null]) {
    if (callback === null) {
      _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion));
      return;
    } else {
      _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion), _unwrap(callback));
      return;
    }
  }

  void readTransaction(SQLTransactionSyncCallback callback) {
    _ptr.readTransaction(_unwrap(callback));
    return;
  }

  void transaction(SQLTransactionSyncCallback callback) {
    _ptr.transaction(_unwrap(callback));
    return;
  }
}
