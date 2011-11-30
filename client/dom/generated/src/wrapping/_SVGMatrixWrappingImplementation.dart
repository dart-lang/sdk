// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGMatrixWrappingImplementation extends DOMWrapperBase implements SVGMatrix {
  _SVGMatrixWrappingImplementation() : super() {}

  static create__SVGMatrixWrappingImplementation() native {
    return new _SVGMatrixWrappingImplementation();
  }

  num get a() { return _get_a(this); }
  static num _get_a(var _this) native;

  void set a(num value) { _set_a(this, value); }
  static void _set_a(var _this, num value) native;

  num get b() { return _get_b(this); }
  static num _get_b(var _this) native;

  void set b(num value) { _set_b(this, value); }
  static void _set_b(var _this, num value) native;

  num get c() { return _get_c(this); }
  static num _get_c(var _this) native;

  void set c(num value) { _set_c(this, value); }
  static void _set_c(var _this, num value) native;

  num get d() { return _get_d(this); }
  static num _get_d(var _this) native;

  void set d(num value) { _set_d(this, value); }
  static void _set_d(var _this, num value) native;

  num get e() { return _get_e(this); }
  static num _get_e(var _this) native;

  void set e(num value) { _set_e(this, value); }
  static void _set_e(var _this, num value) native;

  num get f() { return _get_f(this); }
  static num _get_f(var _this) native;

  void set f(num value) { _set_f(this, value); }
  static void _set_f(var _this, num value) native;

  SVGMatrix flipX() {
    return _flipX(this);
  }
  static SVGMatrix _flipX(receiver) native;

  SVGMatrix flipY() {
    return _flipY(this);
  }
  static SVGMatrix _flipY(receiver) native;

  SVGMatrix inverse() {
    return _inverse(this);
  }
  static SVGMatrix _inverse(receiver) native;

  SVGMatrix multiply(SVGMatrix secondMatrix) {
    return _multiply(this, secondMatrix);
  }
  static SVGMatrix _multiply(receiver, secondMatrix) native;

  SVGMatrix rotate(num angle) {
    return _rotate(this, angle);
  }
  static SVGMatrix _rotate(receiver, angle) native;

  SVGMatrix rotateFromVector(num x, num y) {
    return _rotateFromVector(this, x, y);
  }
  static SVGMatrix _rotateFromVector(receiver, x, y) native;

  SVGMatrix scale(num scaleFactor) {
    return _scale(this, scaleFactor);
  }
  static SVGMatrix _scale(receiver, scaleFactor) native;

  SVGMatrix scaleNonUniform(num scaleFactorX, num scaleFactorY) {
    return _scaleNonUniform(this, scaleFactorX, scaleFactorY);
  }
  static SVGMatrix _scaleNonUniform(receiver, scaleFactorX, scaleFactorY) native;

  SVGMatrix skewX(num angle) {
    return _skewX(this, angle);
  }
  static SVGMatrix _skewX(receiver, angle) native;

  SVGMatrix skewY(num angle) {
    return _skewY(this, angle);
  }
  static SVGMatrix _skewY(receiver, angle) native;

  SVGMatrix translate(num x, num y) {
    return _translate(this, x, y);
  }
  static SVGMatrix _translate(receiver, x, y) native;

  String get typeName() { return "SVGMatrix"; }
}
