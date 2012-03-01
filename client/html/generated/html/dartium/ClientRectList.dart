
class _ClientRectListImpl extends _DOMTypeBase implements ClientRectList {
  _ClientRectListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  ClientRect item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
