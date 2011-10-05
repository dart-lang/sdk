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

  CSSValue getPropertyCSSValue(String propertyName = null) {
    if (propertyName === null) {
      return _getPropertyCSSValue(this);
    } else {
      return _getPropertyCSSValue_2(this, propertyName);
    }
  }
  static CSSValue _getPropertyCSSValue(receiver) native;
  static CSSValue _getPropertyCSSValue_2(receiver, propertyName) native;

  String getPropertyPriority(String propertyName = null) {
    if (propertyName === null) {
      return _getPropertyPriority(this);
    } else {
      return _getPropertyPriority_2(this, propertyName);
    }
  }
  static String _getPropertyPriority(receiver) native;
  static String _getPropertyPriority_2(receiver, propertyName) native;

  String getPropertyShorthand(String propertyName = null) {
    if (propertyName === null) {
      return _getPropertyShorthand(this);
    } else {
      return _getPropertyShorthand_2(this, propertyName);
    }
  }
  static String _getPropertyShorthand(receiver) native;
  static String _getPropertyShorthand_2(receiver, propertyName) native;

  String getPropertyValue(String propertyName = null) {
    if (propertyName === null) {
      return _getPropertyValue(this);
    } else {
      return _getPropertyValue_2(this, propertyName);
    }
  }
  static String _getPropertyValue(receiver) native;
  static String _getPropertyValue_2(receiver, propertyName) native;

  bool isPropertyImplicit(String propertyName = null) {
    if (propertyName === null) {
      return _isPropertyImplicit(this);
    } else {
      return _isPropertyImplicit_2(this, propertyName);
    }
  }
  static bool _isPropertyImplicit(receiver) native;
  static bool _isPropertyImplicit_2(receiver, propertyName) native;

  String item(int index = null) {
    if (index === null) {
      return _item(this);
    } else {
      return _item_2(this, index);
    }
  }
  static String _item(receiver) native;
  static String _item_2(receiver, index) native;

  String removeProperty(String propertyName = null) {
    if (propertyName === null) {
      return _removeProperty(this);
    } else {
      return _removeProperty_2(this, propertyName);
    }
  }
  static String _removeProperty(receiver) native;
  static String _removeProperty_2(receiver, propertyName) native;

  void setProperty(String propertyName = null, String value = null, String priority = null) {
    if (propertyName === null) {
      if (value === null) {
        if (priority === null) {
          _setProperty(this);
          return;
        }
      }
    } else {
      if (value === null) {
        if (priority === null) {
          _setProperty_2(this, propertyName);
          return;
        }
      } else {
        if (priority === null) {
          _setProperty_3(this, propertyName, value);
          return;
        } else {
          _setProperty_4(this, propertyName, value, priority);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setProperty(receiver) native;
  static void _setProperty_2(receiver, propertyName) native;
  static void _setProperty_3(receiver, propertyName, value) native;
  static void _setProperty_4(receiver, propertyName, value, priority) native;

  String get typeName() { return "CSSStyleDeclaration"; }
}
