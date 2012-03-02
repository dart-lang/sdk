
class _SVGMatrixImpl extends _DOMTypeBase implements SVGMatrix {
  _SVGMatrixImpl._wrap(ptr) : super._wrap(ptr);

  num get a() => _wrap(_ptr.a);

  void set a(num value) { _ptr.a = _unwrap(value); }

  num get b() => _wrap(_ptr.b);

  void set b(num value) { _ptr.b = _unwrap(value); }

  num get c() => _wrap(_ptr.c);

  void set c(num value) { _ptr.c = _unwrap(value); }

  num get d() => _wrap(_ptr.d);

  void set d(num value) { _ptr.d = _unwrap(value); }

  num get e() => _wrap(_ptr.e);

  void set e(num value) { _ptr.e = _unwrap(value); }

  num get f() => _wrap(_ptr.f);

  void set f(num value) { _ptr.f = _unwrap(value); }

  SVGMatrix flipX() {
    return _wrap(_ptr.flipX());
  }

  SVGMatrix flipY() {
    return _wrap(_ptr.flipY());
  }

  SVGMatrix inverse() {
    return _wrap(_ptr.inverse());
  }

  SVGMatrix multiply(SVGMatrix secondMatrix) {
    return _wrap(_ptr.multiply(_unwrap(secondMatrix)));
  }

  SVGMatrix rotate(num angle) {
    return _wrap(_ptr.rotate(_unwrap(angle)));
  }

  SVGMatrix rotateFromVector(num x, num y) {
    return _wrap(_ptr.rotateFromVector(_unwrap(x), _unwrap(y)));
  }

  SVGMatrix scale(num scaleFactor) {
    return _wrap(_ptr.scale(_unwrap(scaleFactor)));
  }

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) {
    return _wrap(_ptr.scaleNonUniform(_unwrap(scaleFactorX), _unwrap(scaleFactorY)));
  }

  SVGMatrix skewX(num angle) {
    return _wrap(_ptr.skewX(_unwrap(angle)));
  }

  SVGMatrix skewY(num angle) {
    return _wrap(_ptr.skewY(_unwrap(angle)));
  }

  SVGMatrix translate(num x, num y) {
    return _wrap(_ptr.translate(_unwrap(x), _unwrap(y)));
  }
}
