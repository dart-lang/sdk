// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLOptionElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLOptionElement {
  _HTMLOptionElementWrappingImplementation() : super() {}

  static create__HTMLOptionElementWrappingImplementation() native {
    return new _HTMLOptionElementWrappingImplementation();
  }

  bool get defaultSelected() { return _get_defaultSelected(this); }
  static bool _get_defaultSelected(var _this) native;

  void set defaultSelected(bool value) { _set_defaultSelected(this, value); }
  static void _set_defaultSelected(var _this, bool value) native;

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get_form(this); }
  static HTMLFormElement _get_form(var _this) native;

  int get index() { return _get_index(this); }
  static int _get_index(var _this) native;

  String get label() { return _get_label(this); }
  static String _get_label(var _this) native;

  void set label(String value) { _set_label(this, value); }
  static void _set_label(var _this, String value) native;

  bool get selected() { return _get_selected(this); }
  static bool _get_selected(var _this) native;

  void set selected(bool value) { _set_selected(this, value); }
  static void _set_selected(var _this, bool value) native;

  String get text() { return _get_text(this); }
  static String _get_text(var _this) native;

  void set text(String value) { _set_text(this, value); }
  static void _set_text(var _this, String value) native;

  String get value() { return _get_value(this); }
  static String _get_value(var _this) native;

  void set value(String value) { _set_value(this, value); }
  static void _set_value(var _this, String value) native;

  String get typeName() { return "HTMLOptionElement"; }
}
