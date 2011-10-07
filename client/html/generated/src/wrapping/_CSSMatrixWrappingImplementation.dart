// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class CSSMatrixWrappingImplementation extends DOMWrapperBase implements CSSMatrix {
  CSSMatrixWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}
  factory CSSMatrixWrappingImplementation([String cssValue = null]) {
    
    if (cssValue === null) {
      return LevelDom.wrapCSSMatrix(_rawWindow.createWebKitCSSMatrix());
    } else {
      return LevelDom.wrapCSSMatrix(_rawWindow.createWebKitCSSMatrix(cssValue));
    }
  }

  num get a() { return _ptr.a; }

  void set a(num value) { _ptr.a = value; }

  num get b() { return _ptr.b; }

  void set b(num value) { _ptr.b = value; }

  num get c() { return _ptr.c; }

  void set c(num value) { _ptr.c = value; }

  num get d() { return _ptr.d; }

  void set d(num value) { _ptr.d = value; }

  num get e() { return _ptr.e; }

  void set e(num value) { _ptr.e = value; }

  num get f() { return _ptr.f; }

  void set f(num value) { _ptr.f = value; }

  num get m11() { return _ptr.m11; }

  void set m11(num value) { _ptr.m11 = value; }

  num get m12() { return _ptr.m12; }

  void set m12(num value) { _ptr.m12 = value; }

  num get m13() { return _ptr.m13; }

  void set m13(num value) { _ptr.m13 = value; }

  num get m14() { return _ptr.m14; }

  void set m14(num value) { _ptr.m14 = value; }

  num get m21() { return _ptr.m21; }

  void set m21(num value) { _ptr.m21 = value; }

  num get m22() { return _ptr.m22; }

  void set m22(num value) { _ptr.m22 = value; }

  num get m23() { return _ptr.m23; }

  void set m23(num value) { _ptr.m23 = value; }

  num get m24() { return _ptr.m24; }

  void set m24(num value) { _ptr.m24 = value; }

  num get m31() { return _ptr.m31; }

  void set m31(num value) { _ptr.m31 = value; }

  num get m32() { return _ptr.m32; }

  void set m32(num value) { _ptr.m32 = value; }

  num get m33() { return _ptr.m33; }

  void set m33(num value) { _ptr.m33 = value; }

  num get m34() { return _ptr.m34; }

  void set m34(num value) { _ptr.m34 = value; }

  num get m41() { return _ptr.m41; }

  void set m41(num value) { _ptr.m41 = value; }

  num get m42() { return _ptr.m42; }

  void set m42(num value) { _ptr.m42 = value; }

  num get m43() { return _ptr.m43; }

  void set m43(num value) { _ptr.m43 = value; }

  num get m44() { return _ptr.m44; }

  void set m44(num value) { _ptr.m44 = value; }

  CSSMatrix inverse() {
    return LevelDom.wrapCSSMatrix(_ptr.inverse());
  }

  CSSMatrix multiply(CSSMatrix secondMatrix) {
    return LevelDom.wrapCSSMatrix(_ptr.multiply(LevelDom.unwrap(secondMatrix)));
  }

  CSSMatrix rotate(num rotX, num rotY, num rotZ) {
    return LevelDom.wrapCSSMatrix(_ptr.rotate(rotX, rotY, rotZ));
  }

  CSSMatrix rotateAxisAngle(num x, num y, num z, num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.rotateAxisAngle(x, y, z, angle));
  }

  CSSMatrix scale(num scaleX, num scaleY, num scaleZ) {
    return LevelDom.wrapCSSMatrix(_ptr.scale(scaleX, scaleY, scaleZ));
  }

  void setMatrixValue(String string) {
    _ptr.setMatrixValue(string);
    return;
  }

  CSSMatrix skewX(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewX(angle));
  }

  CSSMatrix skewY(num angle) {
    return LevelDom.wrapCSSMatrix(_ptr.skewY(angle));
  }

  String toString() {
    return _ptr.toString();
  }

  CSSMatrix translate(num x, num y, num z) {
    return LevelDom.wrapCSSMatrix(_ptr.translate(x, y, z));
  }

  String get typeName() { return "CSSMatrix"; }
}
