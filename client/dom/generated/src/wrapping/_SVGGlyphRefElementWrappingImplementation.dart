// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGGlyphRefElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGGlyphRefElement {
  _SVGGlyphRefElementWrappingImplementation() : super() {}

  static create__SVGGlyphRefElementWrappingImplementation() native {
    return new _SVGGlyphRefElementWrappingImplementation();
  }

  num get dx() { return _get_dx(this); }
  static num _get_dx(var _this) native;

  void set dx(num value) { _set_dx(this, value); }
  static void _set_dx(var _this, num value) native;

  num get dy() { return _get_dy(this); }
  static num _get_dy(var _this) native;

  void set dy(num value) { _set_dy(this, value); }
  static void _set_dy(var _this, num value) native;

  String get format() { return _get_format(this); }
  static String _get_format(var _this) native;

  void set format(String value) { _set_format(this, value); }
  static void _set_format(var _this, String value) native;

  String get glyphRef() { return _get_glyphRef(this); }
  static String _get_glyphRef(var _this) native;

  void set glyphRef(String value) { _set_glyphRef(this, value); }
  static void _set_glyphRef(var _this, String value) native;

  num get x() { return _get_x(this); }
  static num _get_x(var _this) native;

  void set x(num value) { _set_x(this, value); }
  static void _set_x(var _this, num value) native;

  num get y() { return _get_y(this); }
  static num _get_y(var _this) native;

  void set y(num value) { _set_y(this, value); }
  static void _set_y(var _this, num value) native;

  // From SVGURIReference

  SVGAnimatedString get href() { return _get_href(this); }
  static SVGAnimatedString _get_href(var _this) native;

  // From SVGStylable

  SVGAnimatedString get className() { return _get_className(this); }
  static SVGAnimatedString _get_className(var _this) native;

  CSSStyleDeclaration get style() { return _get_style_SVGGlyphRefElement(this); }
  static CSSStyleDeclaration _get_style_SVGGlyphRefElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGGlyphRefElement"; }
}
