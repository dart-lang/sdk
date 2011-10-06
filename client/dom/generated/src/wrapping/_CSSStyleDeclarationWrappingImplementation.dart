// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSStyleDeclarationWrappingImplementation extends DOMWrapperBase implements CSSStyleDeclaration {
  _CSSStyleDeclarationWrappingImplementation() : super() {}

  static create__CSSStyleDeclarationWrappingImplementation() native {
    return new _CSSStyleDeclarationWrappingImplementation();
  }

  String get cssText() { return _get__CSSStyleDeclaration_cssText(this); }
  static String _get__CSSStyleDeclaration_cssText(var _this) native;

  void set cssText(String value) { _set__CSSStyleDeclaration_cssText(this, value); }
  static void _set__CSSStyleDeclaration_cssText(var _this, String value) native;

  int get length() { return _get__CSSStyleDeclaration_length(this); }
  static int _get__CSSStyleDeclaration_length(var _this) native;

  CSSRule get parentRule() { return _get__CSSStyleDeclaration_parentRule(this); }
  static CSSRule _get__CSSStyleDeclaration_parentRule(var _this) native;

  CSSValue getPropertyCSSValue(String propertyName) {
    return _getPropertyCSSValue(this, propertyName);
  }
  static CSSValue _getPropertyCSSValue(receiver, propertyName) native;

  String getPropertyPriority(String propertyName) {
    return _getPropertyPriority(this, propertyName);
  }
  static String _getPropertyPriority(receiver, propertyName) native;

  String getPropertyShorthand(String propertyName) {
    return _getPropertyShorthand(this, propertyName);
  }
  static String _getPropertyShorthand(receiver, propertyName) native;

  String getPropertyValue(String propertyName) {
    return _getPropertyValue(this, propertyName);
  }
  static String _getPropertyValue(receiver, propertyName) native;

  bool isPropertyImplicit(String propertyName) {
    return _isPropertyImplicit(this, propertyName);
  }
  static bool _isPropertyImplicit(receiver, propertyName) native;

  String item(int index) {
    return _item(this, index);
  }
  static String _item(receiver, index) native;

  String removeProperty(String propertyName) {
    return _removeProperty(this, propertyName);
  }
  static String _removeProperty(receiver, propertyName) native;

  void setProperty(String propertyName, String value, [String priority = null]) {
    if (priority === null) {
      _setProperty(this, propertyName, value);
      return;
    } else {
      _setProperty_2(this, propertyName, value, priority);
      return;
    }
  }
  static void _setProperty(receiver, propertyName, value) native;
  static void _setProperty_2(receiver, propertyName, value, priority) native;

  String get typeName() { return "CSSStyleDeclaration"; }
}
