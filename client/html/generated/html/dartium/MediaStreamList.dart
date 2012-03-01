
class _MediaStreamListImpl extends _DOMTypeBase implements MediaStreamList {
  _MediaStreamListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  MediaStream item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
