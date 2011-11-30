// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSMediaRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements CSSMediaRule {
  _CSSMediaRuleWrappingImplementation() : super() {}

  static create__CSSMediaRuleWrappingImplementation() native {
    return new _CSSMediaRuleWrappingImplementation();
  }

  CSSRuleList get cssRules() { return _get_cssRules(this); }
  static CSSRuleList _get_cssRules(var _this) native;

  MediaList get media() { return _get_media(this); }
  static MediaList _get_media(var _this) native;

  void deleteRule(int index) {
    _deleteRule(this, index);
    return;
  }
  static void _deleteRule(receiver, index) native;

  int insertRule(String rule, int index) {
    return _insertRule(this, rule, index);
  }
  static int _insertRule(receiver, rule, index) native;

  String get typeName() { return "CSSMediaRule"; }
}
