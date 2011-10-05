// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class CSSStyleDeclarationWrappingImplementation extends DOMWrapperBase implements CSSStyleDeclaration {
  CSSStyleDeclarationWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get cssText() { return _ptr.cssText; }

  void set cssText(String value) { _ptr.cssText = value; }

  int get length() { return _ptr.length; }

  CSSRule get parentRule() { return LevelDom.wrapCSSRule(_ptr.parentRule); }

  CSSValue getPropertyCSSValue(String propertyName) {
    return LevelDom.wrapCSSValue(_ptr.getPropertyCSSValue(propertyName));
  }

  String getPropertyPriority(String propertyName) {
    return _ptr.getPropertyPriority(propertyName);
  }

  String getPropertyShorthand(String propertyName) {
    return _ptr.getPropertyShorthand(propertyName);
  }

  String getPropertyValue(String propertyName) {
    return _ptr.getPropertyValue(propertyName);
  }

  bool isPropertyImplicit(String propertyName) {
    return _ptr.isPropertyImplicit(propertyName);
  }

  String item(int index) {
    return _ptr.item(index);
  }

  String removeProperty(String propertyName) {
    return _ptr.removeProperty(propertyName);
  }

  void setProperty(String propertyName, String value, [String priority = '']) {
    _ptr.setProperty(propertyName, value, priority);
  }

  String get typeName() { return "CSSStyleDeclaration"; }
}
