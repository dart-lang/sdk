// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLLIElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLLIElement {
  _HTMLLIElementWrappingImplementation() : super() {}

  static create__HTMLLIElementWrappingImplementation() native {
    return new _HTMLLIElementWrappingImplementation();
  }

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  int get value() { return _get_value(this); }
  static int _get_value(var _this) native;

  void set value(int value) { _set_value(this, value); }
  static void _set_value(var _this, int value) native;

  String get typeName() { return "HTMLLIElement"; }
}
