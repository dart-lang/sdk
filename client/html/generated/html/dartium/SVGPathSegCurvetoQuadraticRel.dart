
class _SVGPathSegCurvetoQuadraticRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoQuadraticRel {
  _SVGPathSegCurvetoQuadraticRelImpl._wrap(ptr) : super._wrap(ptr);

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get x1() => _wrap(_ptr.x1);

  void set x1(num value) { _ptr.x1 = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }

  num get y1() => _wrap(_ptr.y1);

  void set y1(num value) { _ptr.y1 = _unwrap(value); }
}
