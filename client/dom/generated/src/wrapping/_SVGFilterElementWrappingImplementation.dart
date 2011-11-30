// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGFilterElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGFilterElement {
  _SVGFilterElementWrappingImplementation() : super() {}

  static create__SVGFilterElementWrappingImplementation() native {
    return new _SVGFilterElementWrappingImplementation();
  }

  SVGAnimatedInteger get filterResX() { return _get_filterResX(this); }
  static SVGAnimatedInteger _get_filterResX(var _this) native;

  SVGAnimatedInteger get filterResY() { return _get_filterResY(this); }
  static SVGAnimatedInteger _get_filterResY(var _this) native;

  SVGAnimatedEnumeration get filterUnits() { return _get_filterUnits(this); }
  static SVGAnimatedEnumeration _get_filterUnits(var _this) native;

  SVGAnimatedLength get height() { return _get_height(this); }
  static SVGAnimatedLength _get_height(var _this) native;

  SVGAnimatedEnumeration get primitiveUnits() { return _get_primitiveUnits(this); }
  static SVGAnimatedEnumeration _get_primitiveUnits(var _this) native;

  SVGAnimatedLength get width() { return _get_width(this); }
  static SVGAnimatedLength _get_width(var _this) native;

  SVGAnimatedLength get x() { return _get_x(this); }
  static SVGAnimatedLength _get_x(var _this) native;

  SVGAnimatedLength get y() { return _get_y(this); }
  static SVGAnimatedLength _get_y(var _this) native;

  void setFilterRes(int filterResX, int filterResY) {
    _setFilterRes(this, filterResX, filterResY);
    return;
  }
  static void _setFilterRes(receiver, filterResX, filterResY) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  // From SVGLangSpace

  String get xmllang() { return _get_xmllang(this); }
  static String _get_xmllang(var _this) native;

  void set xmllang(String value) { _set_xmllang(this, value); }
  static void _set_xmllang(var _this, String value) native;

  String get xmlspace() { return _get_xmlspace(this); }
  static String _get_xmlspace(var _this) native;

  void set xmlspace(String value) { _set_xmlspace(this, value); }
  static void _set_xmlspace(var _this, String value) native;

  // From SVGExternalResourcesRequired

  SVGAnimatedBoolean get externalResourcesRequired() { return _get_externalResourcesRequired(this); }
  static SVGAnimatedBoolean _get_externalResourcesRequired(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGFilterElement(this); }
  static CSSStyleDeclaration _get_style_SVGFilterElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGFilterElement"; }
}
