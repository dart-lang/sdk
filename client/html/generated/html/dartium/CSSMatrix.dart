
class _CSSMatrixImpl extends _DOMTypeBase implements CSSMatrix {
  _CSSMatrixImpl._wrap(ptr) : super._wrap(ptr);

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

  num get m11() => _wrap(_ptr.m11);

  void set m11(num value) { _ptr.m11 = _unwrap(value); }

  num get m12() => _wrap(_ptr.m12);

  void set m12(num value) { _ptr.m12 = _unwrap(value); }

  num get m13() => _wrap(_ptr.m13);

  void set m13(num value) { _ptr.m13 = _unwrap(value); }

  num get m14() => _wrap(_ptr.m14);

  void set m14(num value) { _ptr.m14 = _unwrap(value); }

  num get m21() => _wrap(_ptr.m21);

  void set m21(num value) { _ptr.m21 = _unwrap(value); }

  num get m22() => _wrap(_ptr.m22);

  void set m22(num value) { _ptr.m22 = _unwrap(value); }

  num get m23() => _wrap(_ptr.m23);

  void set m23(num value) { _ptr.m23 = _unwrap(value); }

  num get m24() => _wrap(_ptr.m24);

  void set m24(num value) { _ptr.m24 = _unwrap(value); }

  num get m31() => _wrap(_ptr.m31);

  void set m31(num value) { _ptr.m31 = _unwrap(value); }

  num get m32() => _wrap(_ptr.m32);

  void set m32(num value) { _ptr.m32 = _unwrap(value); }

  num get m33() => _wrap(_ptr.m33);

  void set m33(num value) { _ptr.m33 = _unwrap(value); }

  num get m34() => _wrap(_ptr.m34);

  void set m34(num value) { _ptr.m34 = _unwrap(value); }

  num get m41() => _wrap(_ptr.m41);

  void set m41(num value) { _ptr.m41 = _unwrap(value); }

  num get m42() => _wrap(_ptr.m42);

  void set m42(num value) { _ptr.m42 = _unwrap(value); }

  num get m43() => _wrap(_ptr.m43);

  void set m43(num value) { _ptr.m43 = _unwrap(value); }

  num get m44() => _wrap(_ptr.m44);

  void set m44(num value) { _ptr.m44 = _unwrap(value); }

  CSSMatrix inverse() {
    return _wrap(_ptr.inverse());
  }

  CSSMatrix multiply(CSSMatrix secondMatrix) {
    return _wrap(_ptr.multiply(_unwrap(secondMatrix)));
  }

  CSSMatrix rotate(num rotX, num rotY, num rotZ) {
    return _wrap(_ptr.rotate(_unwrap(rotX), _unwrap(rotY), _unwrap(rotZ)));
  }

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) {
    return _wrap(_ptr.rotateAxisAngle(_unwrap(x), _unwrap(y), _unwrap(z), _unwrap(angle)));
  }

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) {
    return _wrap(_ptr.scale(_unwrap(scaleX), _unwrap(scaleY), _unwrap(scaleZ)));
  }

  void setMatrixValue(String string) {
    _ptr.setMatrixValue(_unwrap(string));
    return;
  }

  CSSMatrix skewX(num angle) {
    return _wrap(_ptr.skewX(_unwrap(angle)));
  }

  CSSMatrix skewY(num angle) {
    return _wrap(_ptr.skewY(_unwrap(angle)));
  }

  String toString() {
    return _wrap(_ptr.toString());
  }

  CSSMatrix translate(num x, num y, num z) {
    return _wrap(_ptr.translate(_unwrap(x), _unwrap(y), _unwrap(z)));
  }
}
