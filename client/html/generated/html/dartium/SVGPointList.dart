
class _SVGPointListImpl extends _DOMTypeBase implements SVGPointList {
  _SVGPointListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  SVGPoint appendItem(SVGPoint item) {
    return _wrap(_ptr.appendItem(_unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGPoint getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  SVGPoint initialize(SVGPoint item) {
    return _wrap(_ptr.initialize(_unwrap(item)));
  }

  SVGPoint insertItemBefore(SVGPoint item, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(item), _unwrap(index)));
  }

  SVGPoint removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  SVGPoint replaceItem(SVGPoint item, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(item), _unwrap(index)));
  }
}
