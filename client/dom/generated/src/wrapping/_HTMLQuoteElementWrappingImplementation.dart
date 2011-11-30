// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLQuoteElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLQuoteElement {
  _HTMLQuoteElementWrappingImplementation() : super() {}

  static create__HTMLQuoteElementWrappingImplementation() native {
    return new _HTMLQuoteElementWrappingImplementation();
  }

  String get cite() { return _get_cite(this); }
  static String _get_cite(var _this) native;

  void set cite(String value) { _set_cite(this, value); }
  static void _set_cite(var _this, String value) native;

  String get typeName() { return "HTMLQuoteElement"; }
}
