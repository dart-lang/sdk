
class _DatabaseImpl extends _DOMTypeBase implements Database {
  _DatabaseImpl._wrap(ptr) : super._wrap(ptr);

  String get version() => _wrap(_ptr.version);

  void changeVersion(String oldVersion, String newVersion, [SQLTransactionCallback callback = null, SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (callback === null) {
      if (errorCallback === null) {
        if (successCallback === null) {
          _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion));
          return;
        }
      }
    } else {
      if (errorCallback === null) {
        if (successCallback === null) {
          _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion), _unwrap(callback));
          return;
        }
      } else {
        if (successCallback === null) {
          _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion), _unwrap(callback), _unwrap(errorCallback));
          return;
        } else {
          _ptr.changeVersion(_unwrap(oldVersion), _unwrap(newVersion), _unwrap(callback), _unwrap(errorCallback), _unwrap(successCallback));
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void readTransaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (errorCallback === null) {
      if (successCallback === null) {
        _ptr.readTransaction(_unwrap(callback));
        return;
      }
    } else {
      if (successCallback === null) {
        _ptr.readTransaction(_unwrap(callback), _unwrap(errorCallback));
        return;
      } else {
        _ptr.readTransaction(_unwrap(callback), _unwrap(errorCallback), _unwrap(successCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  void transaction(SQLTransactionCallback callback, [SQLTransactionErrorCallback errorCallback = null, VoidCallback successCallback = null]) {
    if (errorCallback === null) {
      if (successCallback === null) {
        _ptr.transaction(_unwrap(callback));
        return;
      }
    } else {
      if (successCallback === null) {
        _ptr.transaction(_unwrap(callback), _unwrap(errorCallback));
        return;
      } else {
        _ptr.transaction(_unwrap(callback), _unwrap(errorCallback), _unwrap(successCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
