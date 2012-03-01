
class _SVGPathSegLinetoHorizontalRelImpl extends _SVGPathSegImpl implements SVGPathSegLinetoHorizontalRel {
  _SVGPathSegLinetoHorizontalRelImpl._wrap(ptr) : super._wrap(ptr);

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }
}
