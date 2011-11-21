// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGMaskElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGMaskElement {
  _SVGMaskElementWrappingImplementation() : super() {}

  static create__SVGMaskElementWrappingImplementation() native {
    return new _SVGMaskElementWrappingImplementation();
  }

  SVGAnimatedLength get height() { return _get_height(this); }
  static SVGAnimatedLength _get_height(var _this) native;

  SVGAnimatedEnumeration get maskContentUnits() { return _get_maskContentUnits(this); }
  static SVGAnimatedEnumeration _get_maskContentUnits(var _this) native;

  SVGAnimatedEnumeration get maskUnits() { return _get_maskUnits(this); }
  static SVGAnimatedEnumeration _get_maskUnits(var _this) native;

  SVGAnimatedLength get width() { return _get_width(this); }
  static SVGAnimatedLength _get_width(var _this) native;

  SVGAnimatedLength get x() { return _get_x(this); }
  static SVGAnimatedLength _get_x(var _this) native;

  SVGAnimatedLength get y() { return _get_y(this); }
  static SVGAnimatedLength _get_y(var _this) native;

  // From SVGTests

  SVGStringList get requiredExtensions() { return _get_requiredExtensions(this); }
  static SVGStringList _get_requiredExtensions(var _this) native;

  SVGStringList get requiredFeatures() { return _get_requiredFeatures(this); }
  static SVGStringList _get_requiredFeatures(var _this) native;

  SVGStringList get systemLanguage() { return _get_systemLanguage(this); }
  static SVGStringList _get_systemLanguage(var _this) native;

  bool hasExtension(String extension) {
    return _hasExtension(this, extension);
  }
  static bool _hasExtension(receiver, extension) native;

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

  CSSStyleDeclaration get style() { return _get_style_SVGMaskElement(this); }
  static CSSStyleDeclaration _get_style_SVGMaskElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGMaskElement"; }
}
