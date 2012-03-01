
class _SVGNumberListImpl extends _DOMTypeBase implements SVGNumberList {
  _SVGNumberListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  SVGNumber appendItem(SVGNumber item) {
    return _wrap(_ptr.appendItem(_unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGNumber getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  SVGNumber initialize(SVGNumber item) {
    return _wrap(_ptr.initialize(_unwrap(item)));
  }

  SVGNumber insertItemBefore(SVGNumber item, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(item), _unwrap(index)));
  }

  SVGNumber removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  SVGNumber replaceItem(SVGNumber item, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(item), _unwrap(index)));
  }
}
