
class _FileWriterSyncImpl extends _DOMTypeBase implements FileWriterSync {
  _FileWriterSyncImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  int get position() => _wrap(_ptr.position);

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
