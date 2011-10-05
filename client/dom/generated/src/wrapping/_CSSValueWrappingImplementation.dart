// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CSSValueWrappingImplementation extends DOMWrapperBase implements CSSValue {
  _CSSValueWrappingImplementation() : super() {}

  static create__CSSValueWrappingImplementation() native {
    return new _CSSValueWrappingImplementation();
  }

  String get cssText() { return _get__CSSValue_cssText(this); }
  static String _get__CSSValue_cssText(var _this) native;

  void set cssText(String value) { _set__CSSValue_cssText(this, value); }
  static void _set__CSSValue_cssText(var _this, String value) native;

  int get cssValueType() { return _get__CSSValue_cssValueType(this); }
  static int _get__CSSValue_cssValueType(var _this) native;

  String get typeName() { return "CSSValue"; }
}
