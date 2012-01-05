// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLOListElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLOListElement {
  _HTMLOListElementWrappingImplementation() : super() {}

  static create__HTMLOListElementWrappingImplementation() native {
    return new _HTMLOListElementWrappingImplementation();
  }

  bool get compact() { return _get_compact(this); }
  static bool _get_compact(var _this) native;

  void set compact(bool value) { _set_compact(this, value); }
  static void _set_compact(var _this, bool value) native;

  int get start() { return _get_start(this); }
  static int _get_start(var _this) native;

  void set start(int value) { _set_start(this, value); }
  static void _set_start(var _this, int value) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  String get typeName() { return "HTMLOListElement"; }
}
