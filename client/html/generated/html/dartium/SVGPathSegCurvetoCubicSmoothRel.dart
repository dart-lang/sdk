
class _SVGPathSegCurvetoCubicSmoothRelImpl extends _SVGPathSegImpl implements SVGPathSegCurvetoCubicSmoothRel {
  _SVGPathSegCurvetoCubicSmoothRelImpl._wrap(ptr) : super._wrap(ptr);

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get x2() => _wrap(_ptr.x2);

  void set x2(num value) { _ptr.x2 = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }

  num get y2() => _wrap(_ptr.y2);

  void set y2(num value) { _ptr.y2 = _unwrap(value); }
}
