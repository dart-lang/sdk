// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTransformWrappingImplementation extends DOMWrapperBase implements SVGTransform {
  _SVGTransformWrappingImplementation() : super() {}

  static create__SVGTransformWrappingImplementation() native {
    return new _SVGTransformWrappingImplementation();
  }

  num get angle() { return _get_angle(this); }
  static num _get_angle(var _this) native;

  SVGMatrix get matrix() { return _get_matrix(this); }
  static SVGMatrix _get_matrix(var _this) native;

  int get type() { return _get_type(this); }
  static int _get_type(var _this) native;

  void setMatrix(SVGMatrix matrix) {
    _setMatrix(this, matrix);
    return;
  }
  static void _setMatrix(receiver, matrix) native;

  void setRotate(num angle, num cx, num cy) {
    _setRotate(this, angle, cx, cy);
    return;
  }
  static void _setRotate(receiver, angle, cx, cy) native;

  void setScale(num sx, num sy) {
    _setScale(this, sx, sy);
    return;
  }
  static void _setScale(receiver, sx, sy) native;

  void setSkewX(num angle) {
    _setSkewX(this, angle);
    return;
  }
  static void _setSkewX(receiver, angle) native;

  void setSkewY(num angle) {
    _setSkewY(this, angle);
    return;
  }
  static void _setSkewY(receiver, angle) native;

  void setTranslate(num tx, num ty) {
    _setTranslate(this, tx, ty);
    return;
  }
  static void _setTranslate(receiver, tx, ty) native;

  String get typeName() { return "SVGTransform"; }
}
