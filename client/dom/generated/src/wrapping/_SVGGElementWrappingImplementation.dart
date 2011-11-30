// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGGElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGGElement {
  _SVGGElementWrappingImplementation() : super() {}

  static create__SVGGElementWrappingImplementation() native {
    return new _SVGGElementWrappingImplementation();
  }

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

  CSSStyleDeclaration get style() { return _get_style_SVGGElement(this); }
  static CSSStyleDeclaration _get_style_SVGGElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  // From SVGTransformable

  SVGAnimatedTransformList get transform() { return _get_transform(this); }
  static SVGAnimatedTransformList _get_transform(var _this) native;

  // From SVGLocatable

  SVGElement get farthestViewportElement() { return _get_farthestViewportElement(this); }
  static SVGElement _get_farthestViewportElement(var _this) native;

  SVGElement get nearestViewportElement() { return _get_nearestViewportElement(this); }
  static SVGElement _get_nearestViewportElement(var _this) native;

  SVGRect getBBox() {
    return _getBBox(this);
  }
  static SVGRect _getBBox(receiver) native;

  SVGMatrix getCTM() {
    return _getCTM(this);
  }
  static SVGMatrix _getCTM(receiver) native;

  SVGMatrix getScreenCTM() {
    return _getScreenCTM(this);
  }
  static SVGMatrix _getScreenCTM(receiver) native;

  SVGMatrix getTransformToElement(SVGElement element) {
    return _getTransformToElement(this, element);
  }
  static SVGMatrix _getTransformToElement(receiver, element) native;

  String get typeName() { return "SVGGElement"; }
}
