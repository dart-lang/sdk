// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitCSSKeyframeRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements WebKitCSSKeyframeRule {
  _WebKitCSSKeyframeRuleWrappingImplementation() : super() {}

  static create__WebKitCSSKeyframeRuleWrappingImplementation() native {
    return new _WebKitCSSKeyframeRuleWrappingImplementation();
  }

  String get keyText() { return _get_keyText(this); }
  static String _get_keyText(var _this) native;

  void set keyText(String value) { _set_keyText(this, value); }
  static void _set_keyText(var _this, String value) native;

  CSSStyleDeclaration get style() { return _get_style(this); }
  static CSSStyleDeclaration _get_style(var _this) native;

  String get typeName() { return "WebKitCSSKeyframeRule"; }
}
