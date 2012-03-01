
class _IDBTransactionImpl extends _DOMTypeBase implements IDBTransaction {
  _IDBTransactionImpl._wrap(ptr) : super._wrap(ptr);

  IDBDatabase get db() => _wrap(_ptr.db);

  int get mode() => _wrap(_ptr.mode);

  EventListener get onabort() => _wrap(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = _unwrap(value); }

  EventListener get oncomplete() => _wrap(_ptr.oncomplete);

  void set oncomplete(EventListener value) { _ptr.oncomplete = _unwrap(value); }

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  void abort() {
    _ptr.abort();
    return;
  }

  void addEventListener(String type, EventListener listener, [bool useCapture = null]) {
    if (useCapture === null) {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener));
      return;
    } else {
      _ptr.addEventListener(_unwrap(type), _unwrap(listener), _unwrap(useCapture));
      return;
    }
  }

  bool dispatchEvent(Event evt) {
    return _wrap(_ptr.dispatchEvent(_unwrap(evt)));
  }

  IDBObjectStore objectStore(String name) {
    return _wrap(_ptr.objectStore(_unwrap(name)));
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
}
