
class _FileListImpl extends _DOMTypeBase implements FileList {
  _FileListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  File item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
