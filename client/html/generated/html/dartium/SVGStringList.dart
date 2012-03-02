
class _SVGStringListImpl extends _DOMTypeBase implements SVGStringList {
  _SVGStringListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  String appendItem(String item) {
    return _wrap(_ptr.appendItem(_unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  String getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  String initialize(String item) {
    return _wrap(_ptr.initialize(_unwrap(item)));
  }

  String insertItemBefore(String item, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(item), _unwrap(index)));
  }

  String removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  String replaceItem(String item, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(item), _unwrap(index)));
  }
}
