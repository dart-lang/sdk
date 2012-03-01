
class _SVGPathSegLinetoVerticalAbsImpl extends _SVGPathSegImpl implements SVGPathSegLinetoVerticalAbs {
  _SVGPathSegLinetoVerticalAbsImpl._wrap(ptr) : super._wrap(ptr);

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }
}
