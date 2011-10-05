// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSImportRuleWrappingImplementation extends _CSSRuleWrappingImplementation implements CSSImportRule {
  _CSSImportRuleWrappingImplementation() : super() {}

  static create__CSSImportRuleWrappingImplementation() native {
    return new _CSSImportRuleWrappingImplementation();
  }

  String get href() { return _get__CSSImportRule_href(this); }
  static String _get__CSSImportRule_href(var _this) native;

  MediaList get media() { return _get__CSSImportRule_media(this); }
  static MediaList _get__CSSImportRule_media(var _this) native;

  CSSStyleSheet get styleSheet() { return _get__CSSImportRule_styleSheet(this); }
  static CSSStyleSheet _get__CSSImportRule_styleSheet(var _this) native;

  String get typeName() { return "CSSImportRule"; }
}
