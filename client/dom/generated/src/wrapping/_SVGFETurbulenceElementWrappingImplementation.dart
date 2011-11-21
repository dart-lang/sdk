// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFETurbulenceElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGFETurbulenceElement {
  _SVGFETurbulenceElementWrappingImplementation() : super() {}

  static create__SVGFETurbulenceElementWrappingImplementation() native {
    return new _SVGFETurbulenceElementWrappingImplementation();
  }

  SVGAnimatedNumber get baseFrequencyX() { return _get_baseFrequencyX(this); }
  static SVGAnimatedNumber _get_baseFrequencyX(var _this) native;

  SVGAnimatedNumber get baseFrequencyY() { return _get_baseFrequencyY(this); }
  static SVGAnimatedNumber _get_baseFrequencyY(var _this) native;

  SVGAnimatedInteger get numOctaves() { return _get_numOctaves(this); }
  static SVGAnimatedInteger _get_numOctaves(var _this) native;

  SVGAnimatedNumber get seed() { return _get_seed(this); }
  static SVGAnimatedNumber _get_seed(var _this) native;

  SVGAnimatedEnumeration get stitchTiles() { return _get_stitchTiles(this); }
  static SVGAnimatedEnumeration _get_stitchTiles(var _this) native;

  SVGAnimatedEnumeration get type() { return _get_type(this); }
  static SVGAnimatedEnumeration _get_type(var _this) native;

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

  CSSStyleDeclaration get style() { return _get_style_SVGFETurbulenceElement(this); }
  static CSSStyleDeclaration _get_style_SVGFETurbulenceElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGFETurbulenceElement"; }
}
