
class _SVGPathSegArcRelImpl extends _SVGPathSegImpl implements SVGPathSegArcRel {
  _SVGPathSegArcRelImpl._wrap(ptr) : super._wrap(ptr);

  num get angle() => _wrap(_ptr.angle);

  void set angle(num value) { _ptr.angle = _unwrap(value); }

  bool get largeArcFlag() => _wrap(_ptr.largeArcFlag);

  void set largeArcFlag(bool value) { _ptr.largeArcFlag = _unwrap(value); }

  num get r1() => _wrap(_ptr.r1);

  void set r1(num value) { _ptr.r1 = _unwrap(value); }

  num get r2() => _wrap(_ptr.r2);

  void set r2(num value) { _ptr.r2 = _unwrap(value); }

  bool get sweepFlag() => _wrap(_ptr.sweepFlag);

  void set sweepFlag(bool value) { _ptr.sweepFlag = _unwrap(value); }

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }
}
