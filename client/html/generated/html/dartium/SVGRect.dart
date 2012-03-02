
class _SVGRectImpl extends _DOMTypeBase implements SVGRect {
  _SVGRectImpl._wrap(ptr) : super._wrap(ptr);

  num get height() => _wrap(_ptr.height);

  void set height(num value) { _ptr.height = _unwrap(value); }

  num get width() => _wrap(_ptr.width);

  void set width(num value) { _ptr.width = _unwrap(value); }

  num get x() => _wrap(_ptr.x);

  void set x(num value) { _ptr.x = _unwrap(value); }

  num get y() => _wrap(_ptr.y);

  void set y(num value) { _ptr.y = _unwrap(value); }
}
