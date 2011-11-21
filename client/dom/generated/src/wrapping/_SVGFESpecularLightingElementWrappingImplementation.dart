// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFESpecularLightingElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGFESpecularLightingElement {
  _SVGFESpecularLightingElementWrappingImplementation() : super() {}

  static create__SVGFESpecularLightingElementWrappingImplementation() native {
    return new _SVGFESpecularLightingElementWrappingImplementation();
  }

  SVGAnimatedString get in1() { return _get_in1(this); }
  static SVGAnimatedString _get_in1(var _this) native;

  SVGAnimatedNumber get specularConstant() { return _get_specularConstant(this); }
  static SVGAnimatedNumber _get_specularConstant(var _this) native;

  SVGAnimatedNumber get specularExponent() { return _get_specularExponent(this); }
  static SVGAnimatedNumber _get_specularExponent(var _this) native;

  SVGAnimatedNumber get surfaceScale() { return _get_surfaceScale(this); }
  static SVGAnimatedNumber _get_surfaceScale(var _this) native;

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

  CSSStyleDeclaration get style() { return _get_style_SVGFESpecularLightingElement(this); }
  static CSSStyleDeclaration _get_style_SVGFESpecularLightingElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGFESpecularLightingElement"; }
}
