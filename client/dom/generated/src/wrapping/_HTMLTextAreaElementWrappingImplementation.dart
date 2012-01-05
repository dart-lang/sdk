// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTextAreaElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTextAreaElement {
  _HTMLTextAreaElementWrappingImplementation() : super() {}

  static create__HTMLTextAreaElementWrappingImplementation() native {
    return new _HTMLTextAreaElementWrappingImplementation();
  }

  String get accessKey() { return _get_accessKey(this); }
  static String _get_accessKey(var _this) native;

  void set accessKey(String value) { _set_accessKey(this, value); }
  static void _set_accessKey(var _this, String value) native;

  bool get autofocus() { return _get_autofocus(this); }
  static bool _get_autofocus(var _this) native;

  void set autofocus(bool value) { _set_autofocus(this, value); }
  static void _set_autofocus(var _this, bool value) native;

  int get cols() { return _get_cols(this); }
  static int _get_cols(var _this) native;

  void set cols(int value) { _set_cols(this, value); }
  static void _set_cols(var _this, int value) native;

  String get defaultValue() { return _get_defaultValue(this); }
  static String _get_defaultValue(var _this) native;

  void set defaultValue(String value) { _set_defaultValue(this, value); }
  static void _set_defaultValue(var _this, String value) native;

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get_form(this); }
  static HTMLFormElement _get_form(var _this) native;

  NodeList get labels() { return _get_labels(this); }
  static NodeList _get_labels(var _this) native;

  int get maxLength() { return _get_maxLength(this); }
  static int _get_maxLength(var _this) native;

  void set maxLength(int value) { _set_maxLength(this, value); }
  static void _set_maxLength(var _this, int value) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  String get placeholder() { return _get_placeholder(this); }
  static String _get_placeholder(var _this) native;

  void set placeholder(String value) { _set_placeholder(this, value); }
  static void _set_placeholder(var _this, String value) native;

  bool get readOnly() { return _get_readOnly(this); }
  static bool _get_readOnly(var _this) native;

  void set readOnly(bool value) { _set_readOnly(this, value); }
  static void _set_readOnly(var _this, bool value) native;

  bool get required() { return _get_required(this); }
  static bool _get_required(var _this) native;

  void set required(bool value) { _set_required(this, value); }
  static void _set_required(var _this, bool value) native;

  int get rows() { return _get_rows(this); }
  static int _get_rows(var _this) native;

  void set rows(int value) { _set_rows(this, value); }
  static void _set_rows(var _this, int value) native;

  String get selectionDirection() { return _get_selectionDirection(this); }
  static String _get_selectionDirection(var _this) native;

  void set selectionDirection(String value) { _set_selectionDirection(this, value); }
  static void _set_selectionDirection(var _this, String value) native;

  int get selectionEnd() { return _get_selectionEnd(this); }
  static int _get_selectionEnd(var _this) native;

  void set selectionEnd(int value) { _set_selectionEnd(this, value); }
  static void _set_selectionEnd(var _this, int value) native;

  int get selectionStart() { return _get_selectionStart(this); }
  static int _get_selectionStart(var _this) native;

  void set selectionStart(int value) { _set_selectionStart(this, value); }
  static void _set_selectionStart(var _this, int value) native;

  int get textLength() { return _get_textLength(this); }
  static int _get_textLength(var _this) native;

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

  String get wrap() { return _get_wrap(this); }
  static String _get_wrap(var _this) native;

  void set wrap(String value) { _set_wrap(this, value); }
  static void _set_wrap(var _this, String value) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  void select() {
    _select(this);
    return;
  }
  static void _select(receiver) native;

  void setCustomValidity(String error) {
    _setCustomValidity(this, error);
    return;
  }
  static void _setCustomValidity(receiver, error) native;

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _setSelectionRange(this, start, end);
      return;
    } else {
      _setSelectionRange_2(this, start, end, direction);
      return;
    }
  }
  static void _setSelectionRange(receiver, start, end) native;
  static void _setSelectionRange_2(receiver, start, end, direction) native;

  String get typeName() { return "HTMLTextAreaElement"; }
}
