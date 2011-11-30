// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLButtonElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLButtonElement {
  _HTMLButtonElementWrappingImplementation() : super() {}

  static create__HTMLButtonElementWrappingImplementation() native {
    return new _HTMLButtonElementWrappingImplementation();
  }

  String get accessKey() { return _get_accessKey(this); }
  static String _get_accessKey(var _this) native;

  void set accessKey(String value) { _set_accessKey(this, value); }
  static void _set_accessKey(var _this, String value) native;

  bool get autofocus() { return _get_autofocus(this); }
  static bool _get_autofocus(var _this) native;

  void set autofocus(bool value) { _set_autofocus(this, value); }
  static void _set_autofocus(var _this, bool value) native;

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get_form(this); }
  static HTMLFormElement _get_form(var _this) native;

  String get formAction() { return _get_formAction(this); }
  static String _get_formAction(var _this) native;

  void set formAction(String value) { _set_formAction(this, value); }
  static void _set_formAction(var _this, String value) native;

  String get formEnctype() { return _get_formEnctype(this); }
  static String _get_formEnctype(var _this) native;

  void set formEnctype(String value) { _set_formEnctype(this, value); }
  static void _set_formEnctype(var _this, String value) native;

  String get formMethod() { return _get_formMethod(this); }
  static String _get_formMethod(var _this) native;

  void set formMethod(String value) { _set_formMethod(this, value); }
  static void _set_formMethod(var _this, String value) native;

  bool get formNoValidate() { return _get_formNoValidate(this); }
  static bool _get_formNoValidate(var _this) native;

  void set formNoValidate(bool value) { _set_formNoValidate(this, value); }
  static void _set_formNoValidate(var _this, bool value) native;

  String get formTarget() { return _get_formTarget(this); }
  static String _get_formTarget(var _this) native;

  void set formTarget(String value) { _set_formTarget(this, value); }
  static void _set_formTarget(var _this, String value) native;

  NodeList get labels() { return _get_labels(this); }
  static NodeList _get_labels(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  String get validationMessage() { return _get_validationMessage(this); }
  static String _get_validationMessage(var _this) native;

  ValidityState get validity() { return _get_validity(this); }
  static ValidityState _get_validity(var _this) native;

  String get value() { return _get_value(this); }
  static String _get_value(var _this) native;

  void set value(String value) { _set_value(this, value); }
  static void _set_value(var _this, String value) native;

  bool get willValidate() { return _get_willValidate(this); }
  static bool _get_willValidate(var _this) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  void click() {
    _click(this);
    return;
  }
  static void _click(receiver) native;

  void setCustomValidity(String error) {
    _setCustomValidity(this, error);
    return;
  }
  static void _setCustomValidity(receiver, error) native;

  String get typeName() { return "HTMLButtonElement"; }
}
