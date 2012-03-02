
class _WorkerContextImpl extends _DOMTypeBase implements WorkerContext {
  _WorkerContextImpl._wrap(ptr) : super._wrap(ptr);

  WorkerLocation get location() => _wrap(_ptr.location);

  WorkerNavigator get navigator() => _wrap(_ptr.navigator);

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  WorkerContext get self() => _wrap(_ptr.self);

  IDBFactory get webkitIndexedDB() => _wrap(_ptr.webkitIndexedDB);

  NotificationCenter get webkitNotifications() => _wrap(_ptr.webkitNotifications);

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void clearInterval(int handle) {
    _ptr.clearInterval(_unwrap(handle));
    return;
  }

  void clearTimeout(int handle) {
    _ptr.clearTimeout(_unwrap(handle));
    return;
  }

  void close() {
    _ptr.close();
    return;
  }

  bool dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  void importScripts() {
    _ptr.importScripts();
    return;
  }

  Database openDatabase(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) {
    if (creationCallback === null) {
      return _wrap(_ptr.openDatabase(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize)));
    } else {
      return _wrap(_ptr.openDatabase(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize), _unwrap(creationCallback)));
    }
  }

  DatabaseSync openDatabaseSync(String name, String version, String displayName, int estimatedSize, [DatabaseCallback creationCallback = null]) {
    if (creationCallback === null) {
      return _wrap(_ptr.openDatabaseSync(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize)));
    } else {
      return _wrap(_ptr.openDatabaseSync(_unwrap(name), _unwrap(version), _unwrap(displayName), _unwrap(estimatedSize), _unwrap(creationCallback)));
    }
  }

  void removeEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.removeEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  int setInterval(TimeoutHandler handler, int timeout) {
    return _wrap(_ptr.setInterval(_unwrap(handler), _unwrap(timeout)));
  }

  int setTimeout(TimeoutHandler handler, int timeout) {
    return _wrap(_ptr.setTimeout(_unwrap(handler), _unwrap(timeout)));
  }

  void webkitRequestFileSystem(int type, int size, [FileSystemCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.webkitRequestFileSystem(_unwrap(type), _unwrap(size));
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.webkitRequestFileSystem(_unwrap(type), _unwrap(size), _unwrap(successCallback));
        return;
      } else {
        _ptr.webkitRequestFileSystem(_unwrap(type), _unwrap(size), _unwrap(successCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }

  DOMFileSystemSync webkitRequestFileSystemSync(int type, int size) {
    return _wrap(_ptr.webkitRequestFileSystemSync(_unwrap(type), _unwrap(size)));
  }

  EntrySync webkitResolveLocalFileSystemSyncURL(String url) {
    return _wrap(_ptr.webkitResolveLocalFileSystemSyncURL(_unwrap(url)));
  }

  void webkitResolveLocalFileSystemURL(String url, [EntryCallback successCallback = null, ErrorCallback errorCallback = null]) {
    if (successCallback === null) {
      if (errorCallback === null) {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url));
        return;
      }
    } else {
      if (errorCallback === null) {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url), _unwrap(successCallback));
        return;
      } else {
        _ptr.webkitResolveLocalFileSystemURL(_unwrap(url), _unwrap(successCallback), _unwrap(errorCallback));
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
