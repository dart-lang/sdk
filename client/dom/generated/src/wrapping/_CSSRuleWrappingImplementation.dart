// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSRuleWrappingImplementation extends DOMWrapperBase implements CSSRule {
  _CSSRuleWrappingImplementation() : super() {}

  static create__CSSRuleWrappingImplementation() native {
    return new _CSSRuleWrappingImplementation();
  }

  String get cssText() { return _get__CSSRule_cssText(this); }
  static String _get__CSSRule_cssText(var _this) native;

  void set cssText(String value) { _set__CSSRule_cssText(this, value); }
  static void _set__CSSRule_cssText(var _this, String value) native;

  CSSRule get parentRule() { return _get__CSSRule_parentRule(this); }
  static CSSRule _get__CSSRule_parentRule(var _this) native;

  CSSStyleSheet get parentStyleSheet() { return _get__CSSRule_parentStyleSheet(this); }
  static CSSStyleSheet _get__CSSRule_parentStyleSheet(var _this) native;

  int get type() { return _get__CSSRule_type(this); }
  static int _get__CSSRule_type(var _this) native;

  String get typeName() { return "CSSRule"; }
}
