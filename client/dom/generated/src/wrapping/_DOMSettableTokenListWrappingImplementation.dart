// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DOMSettableTokenListWrappingImplementation extends _DOMTokenListWrappingImplementation implements DOMSettableTokenList {
  _DOMSettableTokenListWrappingImplementation() : super() {}

  static create__DOMSettableTokenListWrappingImplementation() native {
    return new _DOMSettableTokenListWrappingImplementation();
  }

  String get value() { return _get_value(this); }
  static String _get_value(var _this) native;

  void set value(String value) { _set_value(this, value); }
  static void _set_value(var _this, String value) native;

  String get typeName() { return "DOMSettableTokenList"; }
}
