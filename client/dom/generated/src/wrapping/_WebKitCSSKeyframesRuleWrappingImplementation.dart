// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitCSSKeyframesRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements WebKitCSSKeyframesRule {
  _WebKitCSSKeyframesRuleWrappingImplementation() : super() {}

  static create__WebKitCSSKeyframesRuleWrappingImplementation() native {
    return new _WebKitCSSKeyframesRuleWrappingImplementation();
  }

  CSSRuleList get cssRules() { return _get__WebKitCSSKeyframesRule_cssRules(this); }
  static CSSRuleList _get__WebKitCSSKeyframesRule_cssRules(var _this) native;

  String get name() { return _get__WebKitCSSKeyframesRule_name(this); }
  static String _get__WebKitCSSKeyframesRule_name(var _this) native;

  void set name(String value) { _set__WebKitCSSKeyframesRule_name(this, value); }
  static void _set__WebKitCSSKeyframesRule_name(var _this, String value) native;

  void deleteRule(String key) {
    _deleteRule(this, key);
    return;
  }
  static void _deleteRule(receiver, key) native;

  WebKitCSSKeyframeRule findRule(String key) {
    return _findRule(this, key);
  }
  static WebKitCSSKeyframeRule _findRule(receiver, key) native;

  void insertRule(String rule) {
    _insertRule(this, rule);
    return;
  }
  static void _insertRule(receiver, rule) native;

  String get typeName() { return "WebKitCSSKeyframesRule"; }
}
