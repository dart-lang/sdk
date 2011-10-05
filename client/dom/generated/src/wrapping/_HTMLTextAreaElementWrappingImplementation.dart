// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLTextAreaElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLTextAreaElement {
  _HTMLTextAreaElementWrappingImplementation() : super() {}

  static create__HTMLTextAreaElementWrappingImplementation() native {
    return new _HTMLTextAreaElementWrappingImplementation();
  }

  String get accessKey() { return _get__HTMLTextAreaElement_accessKey(this); }
  static String _get__HTMLTextAreaElement_accessKey(var _this) native;

  void set accessKey(String value) { _set__HTMLTextAreaElement_accessKey(this, value); }
  static void _set__HTMLTextAreaElement_accessKey(var _this, String value) native;

  bool get autofocus() { return _get__HTMLTextAreaElement_autofocus(this); }
  static bool _get__HTMLTextAreaElement_autofocus(var _this) native;

  void set autofocus(bool value) { _set__HTMLTextAreaElement_autofocus(this, value); }
  static void _set__HTMLTextAreaElement_autofocus(var _this, bool value) native;

  int get cols() { return _get__HTMLTextAreaElement_cols(this); }
  static int _get__HTMLTextAreaElement_cols(var _this) native;

  void set cols(int value) { _set__HTMLTextAreaElement_cols(this, value); }
  static void _set__HTMLTextAreaElement_cols(var _this, int value) native;

  String get defaultValue() { return _get__HTMLTextAreaElement_defaultValue(this); }
  static String _get__HTMLTextAreaElement_defaultValue(var _this) native;

  void set defaultValue(String value) { _set__HTMLTextAreaElement_defaultValue(this, value); }
  static void _set__HTMLTextAreaElement_defaultValue(var _this, String value) native;

  bool get disabled() { return _get__HTMLTextAreaElement_disabled(this); }
  static bool _get__HTMLTextAreaElement_disabled(var _this) native;

  void set disabled(bool value) { _set__HTMLTextAreaElement_disabled(this, value); }
  static void _set__HTMLTextAreaElement_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get__HTMLTextAreaElement_form(this); }
  static HTMLFormElement _get__HTMLTextAreaElement_form(var _this) native;

  NodeList get labels() { return _get__HTMLTextAreaElement_labels(this); }
  static NodeList _get__HTMLTextAreaElement_labels(var _this) native;

  int get maxLength() { return _get__HTMLTextAreaElement_maxLength(this); }
  static int _get__HTMLTextAreaElement_maxLength(var _this) native;

  void set maxLength(int value) { _set__HTMLTextAreaElement_maxLength(this, value); }
  static void _set__HTMLTextAreaElement_maxLength(var _this, int value) native;

  String get name() { return _get__HTMLTextAreaElement_name(this); }
  static String _get__HTMLTextAreaElement_name(var _this) native;

  void set name(String value) { _set__HTMLTextAreaElement_name(this, value); }
  static void _set__HTMLTextAreaElement_name(var _this, String value) native;

  String get placeholder() { return _get__HTMLTextAreaElement_placeholder(this); }
  static String _get__HTMLTextAreaElement_placeholder(var _this) native;

  void set placeholder(String value) { _set__HTMLTextAreaElement_placeholder(this, value); }
  static void _set__HTMLTextAreaElement_placeholder(var _this, String value) native;

  bool get readOnly() { return _get__HTMLTextAreaElement_readOnly(this); }
  static bool _get__HTMLTextAreaElement_readOnly(var _this) native;

  void set readOnly(bool value) { _set__HTMLTextAreaElement_readOnly(this, value); }
  static void _set__HTMLTextAreaElement_readOnly(var _this, bool value) native;

  bool get required() { return _get__HTMLTextAreaElement_required(this); }
  static bool _get__HTMLTextAreaElement_required(var _this) native;

  void set required(bool value) { _set__HTMLTextAreaElement_required(this, value); }
  static void _set__HTMLTextAreaElement_required(var _this, bool value) native;

  int get rows() { return _get__HTMLTextAreaElement_rows(this); }
  static int _get__HTMLTextAreaElement_rows(var _this) native;

  void set rows(int value) { _set__HTMLTextAreaElement_rows(this, value); }
  static void _set__HTMLTextAreaElement_rows(var _this, int value) native;

  String get selectionDirection() { return _get__HTMLTextAreaElement_selectionDirection(this); }
  static String _get__HTMLTextAreaElement_selectionDirection(var _this) native;

  void set selectionDirection(String value) { _set__HTMLTextAreaElement_selectionDirection(this, value); }
  static void _set__HTMLTextAreaElement_selectionDirection(var _this, String value) native;

  int get selectionEnd() { return _get__HTMLTextAreaElement_selectionEnd(this); }
  static int _get__HTMLTextAreaElement_selectionEnd(var _this) native;

  void set selectionEnd(int value) { _set__HTMLTextAreaElement_selectionEnd(this, value); }
  static void _set__HTMLTextAreaElement_selectionEnd(var _this, int value) native;

  int get selectionStart() { return _get__HTMLTextAreaElement_selectionStart(this); }
  static int _get__HTMLTextAreaElement_selectionStart(var _this) native;

  void set selectionStart(int value) { _set__HTMLTextAreaElement_selectionStart(this, value); }
  static void _set__HTMLTextAreaElement_selectionStart(var _this, int value) native;

  int get textLength() { return _get__HTMLTextAreaElement_textLength(this); }
  static int _get__HTMLTextAreaElement_textLength(var _this) native;

  String get type() { return _get__HTMLTextAreaElement_type(this); }
  static String _get__HTMLTextAreaElement_type(var _this) native;

  String get validationMessage() { return _get__HTMLTextAreaElement_validationMessage(this); }
  static String _get__HTMLTextAreaElement_validationMessage(var _this) native;

  ValidityState get validity() { return _get__HTMLTextAreaElement_validity(this); }
  static ValidityState _get__HTMLTextAreaElement_validity(var _this) native;

  String get value() { return _get__HTMLTextAreaElement_value(this); }
  static String _get__HTMLTextAreaElement_value(var _this) native;

  void set value(String value) { _set__HTMLTextAreaElement_value(this, value); }
  static void _set__HTMLTextAreaElement_value(var _this, String value) native;

  bool get willValidate() { return _get__HTMLTextAreaElement_willValidate(this); }
  static bool _get__HTMLTextAreaElement_willValidate(var _this) native;

  String get wrap() { return _get__HTMLTextAreaElement_wrap(this); }
  static String _get__HTMLTextAreaElement_wrap(var _this) native;

  void set wrap(String value) { _set__HTMLTextAreaElement_wrap(this, value); }
  static void _set__HTMLTextAreaElement_wrap(var _this, String value) native;

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

  void setSelectionRange(int start = null, int end = null, String direction = null) {
    if (start === null) {
      if (end === null) {
        if (direction === null) {
          _setSelectionRange(this);
          return;
        }
      }
    } else {
      if (end === null) {
        if (direction === null) {
          _setSelectionRange_2(this, start);
          return;
        }
      } else {
        if (direction === null) {
          _setSelectionRange_3(this, start, end);
          return;
        } else {
          _setSelectionRange_4(this, start, end, direction);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _setSelectionRange(receiver) native;
  static void _setSelectionRange_2(receiver, start) native;
  static void _setSelectionRange_3(receiver, start, end) native;
  static void _setSelectionRange_4(receiver, start, end, direction) native;

  String get typeName() { return "HTMLTextAreaElement"; }
}
