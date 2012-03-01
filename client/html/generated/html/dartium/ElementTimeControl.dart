
class _ElementTimeControlImpl extends _DOMTypeBase implements ElementTimeControl {
  _ElementTimeControlImpl._wrap(ptr) : super._wrap(ptr);

  void beginElement() {
    _ptr.beginElement();
    return;
  }

  void beginElementAt(num offset) {
    _ptr.beginElementAt(_unwrap(offset));
    return;
  }

  void endElement() {
    _ptr.endElement();
    return;
  }

  void endElementAt(num offset) {
    _ptr.endElementAt(_unwrap(offset));
    return;
  }
}
