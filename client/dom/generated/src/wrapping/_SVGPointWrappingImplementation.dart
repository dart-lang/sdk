// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGPointWrappingImplementation extends DOMWrapperBase implements SVGPoint {
  _SVGPointWrappingImplementation() : super() {}

  static create__SVGPointWrappingImplementation() native {
    return new _SVGPointWrappingImplementation();
  }

  num get x() { return _get_x(this); }
  static num _get_x(var _this) native;

  void set x(num value) { _set_x(this, value); }
  static void _set_x(var _this, num value) native;

  num get y() { return _get_y(this); }
  static num _get_y(var _this) native;

  void set y(num value) { _set_y(this, value); }
  static void _set_y(var _this, num value) native;

  SVGPoint matrixTransform(SVGMatrix matrix) {
    return _matrixTransform(this, matrix);
  }
  static SVGPoint _matrixTransform(receiver, matrix) native;

  String get typeName() { return "SVGPoint"; }
}
