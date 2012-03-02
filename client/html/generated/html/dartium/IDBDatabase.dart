
class _IDBDatabaseImpl extends _DOMTypeBase implements IDBDatabase {
  _IDBDatabaseImpl._wrap(ptr) : super._wrap(ptr);

  String get name() => _wrap(_ptr.name);

  List<String> get objectStoreNames() => _wrap(_ptr.objectStoreNames);

  EventListener get onabort() => _wrap(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = _unwrap(value); }

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  EventListener get onversionchange() => _wrap(_ptr.onversionchange);

  void set onversionchange(EventListener value) { _ptr.onversionchange = _unwrap(value); }

  String get version() => _wrap(_ptr.version);

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  void close() {
    _ptr.close();
    return;
  }

  IDBObjectStore createObjectStore(String name) {
    return _wrap(_ptr.createObjectStore(_unwrap(name)));
  }

  void deleteObjectStore(String name) {
    _ptr.deleteObjectStore(_unwrap(name));
    return;
  }

  bool dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
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

  IDBVersionChangeRequest setVersion(String version) {
    return _wrap(_ptr.setVersion(_unwrap(version)));
  }

  IDBTransaction transaction(var storeName_OR_storeNames, int mode) {
    if (storeName_OR_storeNames is List<String>) {
      return _wrap(_ptr.transaction(_unwrap(storeName_OR_storeNames), _unwrap(mode)));
    } else {
      if (storeName_OR_storeNames is String) {
        return _wrap(_ptr.transaction(_unwrap(storeName_OR_storeNames), _unwrap(mode)));
      }
    }
    throw "Incorrect number or type of arguments";
  }
}
