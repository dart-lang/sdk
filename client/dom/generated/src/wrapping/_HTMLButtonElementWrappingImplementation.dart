// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLButtonElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLButtonElement {
  _HTMLButtonElementWrappingImplementation() : super() {}

  static create__HTMLButtonElementWrappingImplementation() native {
    return new _HTMLButtonElementWrappingImplementation();
  }

  String get accessKey() { return _get__HTMLButtonElement_accessKey(this); }
  static String _get__HTMLButtonElement_accessKey(var _this) native;

  void set accessKey(String value) { _set__HTMLButtonElement_accessKey(this, value); }
  static void _set__HTMLButtonElement_accessKey(var _this, String value) native;

  bool get autofocus() { return _get__HTMLButtonElement_autofocus(this); }
  static bool _get__HTMLButtonElement_autofocus(var _this) native;

  void set autofocus(bool value) { _set__HTMLButtonElement_autofocus(this, value); }
  static void _set__HTMLButtonElement_autofocus(var _this, bool value) native;

  bool get disabled() { return _get__HTMLButtonElement_disabled(this); }
  static bool _get__HTMLButtonElement_disabled(var _this) native;

  void set disabled(bool value) { _set__HTMLButtonElement_disabled(this, value); }
  static void _set__HTMLButtonElement_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get__HTMLButtonElement_form(this); }
  static HTMLFormElement _get__HTMLButtonElement_form(var _this) native;

  String get formAction() { return _get__HTMLButtonElement_formAction(this); }
  static String _get__HTMLButtonElement_formAction(var _this) native;

  void set formAction(String value) { _set__HTMLButtonElement_formAction(this, value); }
  static void _set__HTMLButtonElement_formAction(var _this, String value) native;

  String get formEnctype() { return _get__HTMLButtonElement_formEnctype(this); }
  static String _get__HTMLButtonElement_formEnctype(var _this) native;

  void set formEnctype(String value) { _set__HTMLButtonElement_formEnctype(this, value); }
  static void _set__HTMLButtonElement_formEnctype(var _this, String value) native;

  String get formMethod() { return _get__HTMLButtonElement_formMethod(this); }
  static String _get__HTMLButtonElement_formMethod(var _this) native;

  void set formMethod(String value) { _set__HTMLButtonElement_formMethod(this, value); }
  static void _set__HTMLButtonElement_formMethod(var _this, String value) native;

  bool get formNoValidate() { return _get__HTMLButtonElement_formNoValidate(this); }
  static bool _get__HTMLButtonElement_formNoValidate(var _this) native;

  void set formNoValidate(bool value) { _set__HTMLButtonElement_formNoValidate(this, value); }
  static void _set__HTMLButtonElement_formNoValidate(var _this, bool value) native;

  String get formTarget() { return _get__HTMLButtonElement_formTarget(this); }
  static String _get__HTMLButtonElement_formTarget(var _this) native;

  void set formTarget(String value) { _set__HTMLButtonElement_formTarget(this, value); }
  static void _set__HTMLButtonElement_formTarget(var _this, String value) native;

  NodeList get labels() { return _get__HTMLButtonElement_labels(this); }
  static NodeList _get__HTMLButtonElement_labels(var _this) native;

  String get name() { return _get__HTMLButtonElement_name(this); }
  static String _get__HTMLButtonElement_name(var _this) native;

  void set name(String value) { _set__HTMLButtonElement_name(this, value); }
  static void _set__HTMLButtonElement_name(var _this, String value) native;

  String get type() { return _get__HTMLButtonElement_type(this); }
  static String _get__HTMLButtonElement_type(var _this) native;

  String get validationMessage() { return _get__HTMLButtonElement_validationMessage(this); }
  static String _get__HTMLButtonElement_validationMessage(var _this) native;

  ValidityState get validity() { return _get__HTMLButtonElement_validity(this); }
  static ValidityState _get__HTMLButtonElement_validity(var _this) native;

  String get value() { return _get__HTMLButtonElement_value(this); }
  static String _get__HTMLButtonElement_value(var _this) native;

  void set value(String value) { _set__HTMLButtonElement_value(this, value); }
  static void _set__HTMLButtonElement_value(var _this, String value) native;

  bool get willValidate() { return _get__HTMLButtonElement_willValidate(this); }
  static bool _get__HTMLButtonElement_willValidate(var _this) native;

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
