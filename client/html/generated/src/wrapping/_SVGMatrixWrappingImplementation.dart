// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SVGMatrixWrappingImplementation extends DOMWrapperBase implements SVGMatrix {
  SVGMatrixWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

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

  SVGMatrix flipX() {
    return LevelDom.wrapSVGMatrix(_ptr.flipX());
  }

  SVGMatrix flipY() {
    return LevelDom.wrapSVGMatrix(_ptr.flipY());
  }

  SVGMatrix inverse() {
    return LevelDom.wrapSVGMatrix(_ptr.inverse());
  }

  SVGMatrix multiply(SVGMatrix secondMatrix) {
    return LevelDom.wrapSVGMatrix(_ptr.multiply(LevelDom.unwrap(secondMatrix)));
  }

  SVGMatrix rotate(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.rotate(angle));
  }

  SVGMatrix rotateFromVector(num x, num y) {
    return LevelDom.wrapSVGMatrix(_ptr.rotateFromVector(x, y));
  }

  SVGMatrix scale(num scaleFactor) {
    return LevelDom.wrapSVGMatrix(_ptr.scale(scaleFactor));
  }

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) {
    return LevelDom.wrapSVGMatrix(_ptr.scaleNonUniform(scaleFactorX, scaleFactorY));
  }

  SVGMatrix skewX(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.skewX(angle));
  }

  SVGMatrix skewY(num angle) {
    return LevelDom.wrapSVGMatrix(_ptr.skewY(angle));
  }

  SVGMatrix translate(num x, num y) {
    return LevelDom.wrapSVGMatrix(_ptr.translate(x, y));
  }
}
