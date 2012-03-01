
class _SVGPointImpl extends _DOMTypeBase implements SVGPoint {
  _SVGPointImpl._wrap(ptr) : super._wrap(ptr);

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }

  SVGPoint matrixTransform(SVGMatrix matrix) {
    return _wrap(_ptr.matrixTransform(_unwrap(matrix)));
  }
}
