
class _IDBRequestImpl extends _DOMTypeBase implements IDBRequest {
  _IDBRequestImpl._wrap(ptr) : super._wrap(ptr);

  int get errorCode() => _wrap(_ptr.errorCode);

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  EventListener get onsuccess() => _wrap(_ptr.onsuccess);

  void set onsuccess(EventListener value) { _ptr.onsuccess = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  IDBAny get result() => _wrap(_ptr.result);

  IDBAny get source() => _wrap(_ptr.source);

  IDBTransaction get transaction() => _wrap(_ptr.transaction);

  String get webkitErrorMessage() => _wrap(_ptr.webkitErrorMessage);

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
