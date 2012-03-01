
class _AnimationListImpl extends _DOMTypeBase implements AnimationList {
  _AnimationListImpl._wrap(ptr) : super._wrap(ptr);

  int get length() => _wrap(_ptr.length);

  Animation item(int index) {
    return _wrap(_ptr.item(_unwrap(index)));
  }
}
