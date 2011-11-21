// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFEGaussianBlurElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGFEGaussianBlurElement {
  _SVGFEGaussianBlurElementWrappingImplementation() : super() {}

  static create__SVGFEGaussianBlurElementWrappingImplementation() native {
    return new _SVGFEGaussianBlurElementWrappingImplementation();
  }

  SVGAnimatedString get in1() { return _get_in1(this); }
  static SVGAnimatedString _get_in1(var _this) native;

  SVGAnimatedNumber get stdDeviationX() { return _get_stdDeviationX(this); }
  static SVGAnimatedNumber _get_stdDeviationX(var _this) native;

  SVGAnimatedNumber get stdDeviationY() { return _get_stdDeviationY(this); }
  static SVGAnimatedNumber _get_stdDeviationY(var _this) native;

  void setStdDeviation(num stdDeviationX, num stdDeviationY) {
    _setStdDeviation(this, stdDeviationX, stdDeviationY);
    return;
  }
  static void _setStdDeviation(receiver, stdDeviationX, stdDeviationY) native;

  // From SVGFilterPrimitiveStandardAttributes

  SVGAnimatedLength get height() { return _get_height(this); }
  static SVGAnimatedLength _get_height(var _this) native;

  SVGAnimatedString get result() { return _get_result(this); }
  static SVGAnimatedString _get_result(var _this) native;

  SVGAnimatedLength get width() { return _get_width(this); }
  static SVGAnimatedLength _get_width(var _this) native;

  SVGAnimatedLength get x() { return _get_x(this); }
  static SVGAnimatedLength _get_x(var _this) native;

  SVGAnimatedLength get y() { return _get_y(this); }
  static SVGAnimatedLength _get_y(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGFEGaussianBlurElement(this); }
  static CSSStyleDeclaration _get_style_SVGFEGaussianBlurElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGFEGaussianBlurElement"; }
}
