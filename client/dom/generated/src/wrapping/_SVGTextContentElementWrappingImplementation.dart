// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _SVGTextContentElementWrappingImplementation extends _SVGElementWrappingImplementation implements SVGTextContentElement {
  _SVGTextContentElementWrappingImplementation() : super() {}

  static create__SVGTextContentElementWrappingImplementation() native {
    return new _SVGTextContentElementWrappingImplementation();
  }

  SVGAnimatedEnumeration get lengthAdjust() { return _get_lengthAdjust(this); }
  static SVGAnimatedEnumeration _get_lengthAdjust(var _this) native;

  SVGAnimatedLength get textLength() { return _get_textLength(this); }
  static SVGAnimatedLength _get_textLength(var _this) native;

  int getCharNumAtPosition(SVGPoint point) {
    return _getCharNumAtPosition(this, point);
  }
  static int _getCharNumAtPosition(receiver, point) native;

  num getComputedTextLength() {
    return _getComputedTextLength(this);
  }
  static num _getComputedTextLength(receiver) native;

  SVGPoint getEndPositionOfChar(int offset) {
    return _getEndPositionOfChar(this, offset);
  }
  static SVGPoint _getEndPositionOfChar(receiver, offset) native;

  SVGRect getExtentOfChar(int offset) {
    return _getExtentOfChar(this, offset);
  }
  static SVGRect _getExtentOfChar(receiver, offset) native;

  int getNumberOfChars() {
    return _getNumberOfChars(this);
  }
  static int _getNumberOfChars(receiver) native;

  num getRotationOfChar(int offset) {
    return _getRotationOfChar(this, offset);
  }
  static num _getRotationOfChar(receiver, offset) native;

  SVGPoint getStartPositionOfChar(int offset) {
    return _getStartPositionOfChar(this, offset);
  }
  static SVGPoint _getStartPositionOfChar(receiver, offset) native;

  num getSubStringLength(int offset, int length) {
    return _getSubStringLength(this, offset, length);
  }
  static num _getSubStringLength(receiver, offset, length) native;

  void selectSubString(int offset, int length) {
    _selectSubString(this, offset, length);
    return;
  }
  static void _selectSubString(receiver, offset, length) native;

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

  CSSStyleDeclaration get style() { return _get_style_SVGTextContentElement(this); }
  static CSSStyleDeclaration _get_style_SVGTextContentElement(var _this) native;

  CSSValue getPresentationAttribute(String name) {
    return _getPresentationAttribute(this, name);
  }
  static CSSValue _getPresentationAttribute(receiver, name) native;

  String get typeName() { return "SVGTextContentElement"; }
}
