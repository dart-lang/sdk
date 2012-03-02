
class _FileWriterImpl extends _DOMTypeBase implements FileWriter {
  _FileWriterImpl._wrap(ptr) : super._wrap(ptr);

  FileError get error() => _wrap(_ptr.error);

  int get length() => _wrap(_ptr.length);

  EventListener get onabort() => _wrap(_ptr.onabort);

  void set onabort(EventListener value) { _ptr.onabort = _unwrap(value); }

  EventListener get onerror() => _wrap(_ptr.onerror);

  void set onerror(EventListener value) { _ptr.onerror = _unwrap(value); }

  EventListener get onprogress() => _wrap(_ptr.onprogress);

  void set onprogress(EventListener value) { _ptr.onprogress = _unwrap(value); }

  EventListener get onwrite() => _wrap(_ptr.onwrite);

  void set onwrite(EventListener value) { _ptr.onwrite = _unwrap(value); }

  EventListener get onwriteend() => _wrap(_ptr.onwriteend);

  void set onwriteend(EventListener value) { _ptr.onwriteend = _unwrap(value); }

  EventListener get onwritestart() => _wrap(_ptr.onwritestart);

  void set onwritestart(EventListener value) { _ptr.onwritestart = _unwrap(value); }

  int get position() => _wrap(_ptr.position);

  int get readyState() => _wrap(_ptr.readyState);

  void abort() {
    _ptr.abort();
    return;
  }

  void seek(int position) {
    _ptr.seek(_unwrap(position));
    return;
  }

  void truncate(int size) {
    _ptr.truncate(_unwrap(size));
    return;
  }

  void write(Blob data) {
    _ptr.write(_unwrap(data));
    return;
  }
}
