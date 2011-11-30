// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLStyleElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLStyleElement {
  _HTMLStyleElementWrappingImplementation() : super() {}

  static create__HTMLStyleElementWrappingImplementation() native {
    return new _HTMLStyleElementWrappingImplementation();
  }

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  String get media() { return _get_media(this); }
  static String _get_media(var _this) native;

  void set media(String value) { _set_media(this, value); }
  static void _set_media(var _this, String value) native;

  StyleSheet get sheet() { return _get_sheet(this); }
  static StyleSheet _get_sheet(var _this) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  String get typeName() { return "HTMLStyleElement"; }
}
