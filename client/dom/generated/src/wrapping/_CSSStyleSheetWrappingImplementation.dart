// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSStyleSheetWrappingImplementation extends _StyleSheetWrappingImplementation implements CSSStyleSheet {
  _CSSStyleSheetWrappingImplementation() : super() {}

  static create__CSSStyleSheetWrappingImplementation() native {
    return new _CSSStyleSheetWrappingImplementation();
  }

  CSSRuleList get cssRules() { return _get__CSSStyleSheet_cssRules(this); }
  static CSSRuleList _get__CSSStyleSheet_cssRules(var _this) native;

  CSSRule get ownerRule() { return _get__CSSStyleSheet_ownerRule(this); }
  static CSSRule _get__CSSStyleSheet_ownerRule(var _this) native;

  CSSRuleList get rules() { return _get__CSSStyleSheet_rules(this); }
  static CSSRuleList _get__CSSStyleSheet_rules(var _this) native;

  int addRule(String selector, String style, [int index = null]) {
    if (index === null) {
      return _addRule(this, selector, style);
    } else {
      return _addRule_2(this, selector, style, index);
    }
  }
  static int _addRule(receiver, selector, style) native;
  static int _addRule_2(receiver, selector, style, index) native;

  void deleteRule(int index) {
    _deleteRule(this, index);
    return;
  }
  static void _deleteRule(receiver, index) native;

  int insertRule(String rule, int index) {
    return _insertRule(this, rule, index);
  }
  static int _insertRule(receiver, rule, index) native;

  void removeRule(int index) {
    _removeRule(this, index);
    return;
  }
  static void _removeRule(receiver, index) native;

  String get typeName() { return "CSSStyleSheet"; }
}
