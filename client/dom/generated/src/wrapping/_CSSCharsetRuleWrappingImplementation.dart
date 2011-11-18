// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSCharsetRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements CSSCharsetRule {
  _CSSCharsetRuleWrappingImplementation() : super() {}

  static create__CSSCharsetRuleWrappingImplementation() native {
    return new _CSSCharsetRuleWrappingImplementation();
  }

  String get encoding() { return _get_encoding(this); }
  static String _get_encoding(var _this) native;

  void set encoding(String value) { _set_encoding(this, value); }
  static void _set_encoding(var _this, String value) native;

  String get typeName() { return "CSSCharsetRule"; }
}
