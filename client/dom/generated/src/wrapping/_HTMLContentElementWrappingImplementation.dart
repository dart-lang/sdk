// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLContentElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLContentElement {
  _HTMLContentElementWrappingImplementation() : super() {}

  static create__HTMLContentElementWrappingImplementation() native {
    return new _HTMLContentElementWrappingImplementation();
  }

  String get select() { return _get_select(this); }
  static String _get_select(var _this) native;

  void set select(String value) { _set_select(this, value); }
  static void _set_select(var _this, String value) native;

  String get typeName() { return "HTMLContentElement"; }
}
