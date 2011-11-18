// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLFormElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLFormElement {
  _HTMLFormElementWrappingImplementation() : super() {}

  static create__HTMLFormElementWrappingImplementation() native {
    return new _HTMLFormElementWrappingImplementation();
  }

  String get acceptCharset() { return _get_acceptCharset(this); }
  static String _get_acceptCharset(var _this) native;

  void set acceptCharset(String value) { _set_acceptCharset(this, value); }
  static void _set_acceptCharset(var _this, String value) native;

  String get action() { return _get_action(this); }
  static String _get_action(var _this) native;

  void set action(String value) { _set_action(this, value); }
  static void _set_action(var _this, String value) native;

  String get autocomplete() { return _get_autocomplete(this); }
  static String _get_autocomplete(var _this) native;

  void set autocomplete(String value) { _set_autocomplete(this, value); }
  static void _set_autocomplete(var _this, String value) native;

  HTMLCollection get elements() { return _get_elements(this); }
  static HTMLCollection _get_elements(var _this) native;

  String get encoding() { return _get_encoding(this); }
  static String _get_encoding(var _this) native;

  void set encoding(String value) { _set_encoding(this, value); }
  static void _set_encoding(var _this, String value) native;

  String get enctype() { return _get_enctype(this); }
  static String _get_enctype(var _this) native;

  void set enctype(String value) { _set_enctype(this, value); }
  static void _set_enctype(var _this, String value) native;

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  String get method() { return _get_method(this); }
  static String _get_method(var _this) native;

  void set method(String value) { _set_method(this, value); }
  static void _set_method(var _this, String value) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  bool get noValidate() { return _get_noValidate(this); }
  static bool _get_noValidate(var _this) native;

  void set noValidate(bool value) { _set_noValidate(this, value); }
  static void _set_noValidate(var _this, bool value) native;

  String get target() { return _get_target(this); }
  static String _get_target(var _this) native;

  void set target(String value) { _set_target(this, value); }
  static void _set_target(var _this, String value) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  void reset() {
    _reset(this);
    return;
  }
  static void _reset(receiver) native;

  void submit() {
    _submit(this);
    return;
  }
  static void _submit(receiver) native;

  String get typeName() { return "HTMLFormElement"; }
}
