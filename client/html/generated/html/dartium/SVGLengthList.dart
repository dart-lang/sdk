
class _SVGLengthListImpl extends _DOMTypeBase implements SVGLengthList {
  _SVGLengthListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  SVGLength appendItem(SVGLength item) {
    return _wrap(_ptr.appendItem(_unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGLength getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  SVGLength initialize(SVGLength item) {
    return _wrap(_ptr.initialize(_unwrap(item)));
  }

  SVGLength insertItemBefore(SVGLength item, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(item), _unwrap(index)));
  }

  SVGLength removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  SVGLength replaceItem(SVGLength item, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(item), _unwrap(index)));
  }
}
