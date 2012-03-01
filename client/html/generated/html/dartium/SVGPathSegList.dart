
class _SVGPathSegListImpl extends _DOMTypeBase implements SVGPathSegList {
  _SVGPathSegListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  SVGPathSeg appendItem(SVGPathSeg newItem) {
    return _wrap(_ptr.appendItem(_unwrap(newItem)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPathSeg getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  SVGPathSeg initialize(SVGPathSeg newItem) {
    return _wrap(_ptr.initialize(_unwrap(newItem)));
  }

  SVGPathSeg insertItemBefore(SVGPathSeg newItem, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(newItem), _unwrap(index)));
  }

  SVGPathSeg removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  SVGPathSeg replaceItem(SVGPathSeg newItem, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(newItem), _unwrap(index)));
  }
}
