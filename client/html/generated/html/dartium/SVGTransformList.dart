
class _SVGTransformListImpl extends _DOMTypeBase implements SVGTransformList {
  _SVGTransformListImpl._wrap(ptr) : super._wrap(ptr);

  int get numberOfItems() => _wrap(_ptr.numberOfItems);

  SVGTransform appendItem(SVGTransform item) {
    return _wrap(_ptr.appendItem(_unwrap(item)));
  }

  void clear() {
    _ptr.clear();
    return;
  }

  SVGTransform consolidate() {
    return _wrap(_ptr.consolidate());
  }

  SVGTransform createSVGTransformFromMatrix(SVGMatrix matrix) {
    return _wrap(_ptr.createSVGTransformFromMatrix(_unwrap(matrix)));
  }

  SVGTransform getItem(int index) {
    return _wrap(_ptr.getItem(_unwrap(index)));
  }

  SVGTransform initialize(SVGTransform item) {
    return _wrap(_ptr.initialize(_unwrap(item)));
  }

  SVGTransform insertItemBefore(SVGTransform item, int index) {
    return _wrap(_ptr.insertItemBefore(_unwrap(item), _unwrap(index)));
  }

  SVGTransform removeItem(int index) {
    return _wrap(_ptr.removeItem(_unwrap(index)));
  }

  SVGTransform replaceItem(SVGTransform item, int index) {
    return _wrap(_ptr.replaceItem(_unwrap(item), _unwrap(index)));
  }
}
