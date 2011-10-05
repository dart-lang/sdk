// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSMediaRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements CSSMediaRule {
  _CSSMediaRuleWrappingImplementation() : super() {}

  static create__CSSMediaRuleWrappingImplementation() native {
    return new _CSSMediaRuleWrappingImplementation();
  }

  CSSRuleList get cssRules() { return _get__CSSMediaRule_cssRules(this); }
  static CSSRuleList _get__CSSMediaRule_cssRules(var _this) native;

  MediaList get media() { return _get__CSSMediaRule_media(this); }
  static MediaList _get__CSSMediaRule_media(var _this) native;

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

  String get typeName() { return "CSSMediaRule"; }
}
