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

  int addRule(String selector = null, String style = null, int index = null) {
    if (selector === null) {
      if (style === null) {
        if (index === null) {
          return _addRule(this);
        }
      }
    } else {
      if (style === null) {
        if (index === null) {
          return _addRule_2(this, selector);
        }
      } else {
        if (index === null) {
          return _addRule_3(this, selector, style);
        } else {
          return _addRule_4(this, selector, style, index);
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static int _addRule(receiver) native;
  static int _addRule_2(receiver, selector) native;
  static int _addRule_3(receiver, selector, style) native;
  static int _addRule_4(receiver, selector, style, index) native;

  void deleteRule(int index = null) {
    if (index === null) {
      _deleteRule(this);
      return;
    } else {
      _deleteRule_2(this, index);
      return;
    }
  }
  static void _deleteRule(receiver) native;
  static void _deleteRule_2(receiver, index) native;

  int insertRule(String rule = null, int index = null) {
    if (rule === null) {
      if (index === null) {
        return _insertRule(this);
      }
    } else {
      if (index === null) {
        return _insertRule_2(this, rule);
      } else {
        return _insertRule_3(this, rule, index);
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static int _insertRule(receiver) native;
  static int _insertRule_2(receiver, rule) native;
  static int _insertRule_3(receiver, rule, index) native;

  void removeRule(int index = null) {
    if (index === null) {
      _removeRule(this);
      return;
    } else {
      _removeRule_2(this, index);
      return;
    }
  }
  static void _removeRule(receiver) native;
  static void _removeRule_2(receiver, index) native;

  String get typeName() { return "CSSStyleSheet"; }
}
