
class _FileReaderImpl extends _DOMTypeBase implements FileReader {
  _FileReaderImpl._wrap(ptr) : super._wrap(ptr);

  FileError get error() => _wrap(_ptr.error);

  EventListener get onabort() => _wrap(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = _unwrap(value); }

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  EventListener get onload() => _wrap(_ptr.onload);

  void set onload(EventListener value) { _ptr.onload = _unwrap(value); }

  EventListener get onloadend() => _wrap(_ptr.onloadend);

  void set onloadend(EventListener value) { _ptr.onloadend = _unwrap(value); }

  EventListener get onloadstart() => _wrap(_ptr.onloadstart);

  void set onloadstart(EventListener value) { _ptr.onloadstart = _unwrap(value); }

  EventListener get onprogress() => _wrap(_ptr.onprogress);

  void set onprogress(EventListener value) { _ptr.onprogress = _unwrap(value); }

  int get readyState() => _wrap(_ptr.readyState);

  Object get result() => _wrap(_ptr.result);

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

  void readAsArrayBuffer(Blob blob) {
    _ptr.readAsArrayBuffer(_unwrap(blob));
    return;
  }

  void readAsBinaryString(Blob blob) {
    _ptr.readAsBinaryString(_unwrap(blob));
    return;
  }

  void readAsDataURL(Blob blob) {
    _ptr.readAsDataURL(_unwrap(blob));
    return;
  }

  void readAsText(Blob blob, [String encoding = null]) {
    if (encoding === null) {
      _ptr.readAsText(_unwrap(blob));
      return;
    } else {
      _ptr.readAsText(_unwrap(blob), _unwrap(encoding));
      return;
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
}
