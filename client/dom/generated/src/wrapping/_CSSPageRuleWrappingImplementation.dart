// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSPageRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements CSSPageRule {
  _CSSPageRuleWrappingImplementation() : super() {}

  static create__CSSPageRuleWrappingImplementation() native {
    return new _CSSPageRuleWrappingImplementation();
  }

  String get selectorText() { return _get__CSSPageRule_selectorText(this); }
  static String _get__CSSPageRule_selectorText(var _this) native;

  void set selectorText(String value) { _set__CSSPageRule_selectorText(this, value); }
  static void _set__CSSPageRule_selectorText(var _this, String value) native;

  CSSStyleDeclaration get style() { return _get__CSSPageRule_style(this); }
  static CSSStyleDeclaration _get__CSSPageRule_style(var _this) native;

  String get typeName() { return "CSSPageRule"; }
}
