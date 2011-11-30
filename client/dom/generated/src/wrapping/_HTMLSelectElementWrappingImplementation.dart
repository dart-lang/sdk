// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLSelectElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLSelectElement {
  _HTMLSelectElementWrappingImplementation() : super() {}

  static create__HTMLSelectElementWrappingImplementation() native {
    return new _HTMLSelectElementWrappingImplementation();
  }

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

  NodeList get labels() { return _get_labels(this); }
  static NodeList _get_labels(var _this) native;

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  void set length(int value) { _set_length(this, value); }
  static void _set_length(var _this, int value) native;

  bool get multiple() { return _get_multiple(this); }
  static bool _get_multiple(var _this) native;

  void set multiple(bool value) { _set_multiple(this, value); }
  static void _set_multiple(var _this, bool value) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  HTMLOptionsCollection get options() { return _get_options(this); }
  static HTMLOptionsCollection _get_options(var _this) native;

  bool get required() { return _get_required(this); }
  static bool _get_required(var _this) native;

  void set required(bool value) { _set_required(this, value); }
  static void _set_required(var _this, bool value) native;

  int get selectedIndex() { return _get_selectedIndex(this); }
  static int _get_selectedIndex(var _this) native;

  void set selectedIndex(int value) { _set_selectedIndex(this, value); }
  static void _set_selectedIndex(var _this, int value) native;

  int get size() { return _get_size(this); }
  static int _get_size(var _this) native;

  void set size(int value) { _set_size(this, value); }
  static void _set_size(var _this, int value) native;

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

  void add(HTMLElement element, HTMLElement before) {
    _add(this, element, before);
    return;
  }
  static void _add(receiver, element, before) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  Node item(int index) {
    return _item(this, index);
  }
  static Node _item(receiver, index) native;

  Node namedItem(String name) {
    return _namedItem(this, name);
  }
  static Node _namedItem(receiver, name) native;

  void remove(var index_OR_option) {
    if (index_OR_option is int) {
      _remove(this, index_OR_option);
      return;
    } else {
      if (index_OR_option is HTMLOptionElement) {
        _remove_2(this, index_OR_option);
        return;
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _remove(receiver, index_OR_option) native;
  static void _remove_2(receiver, index_OR_option) native;

  void setCustomValidity(String error) {
    _setCustomValidity(this, error);
    return;
  }
  static void _setCustomValidity(receiver, error) native;

  String get typeName() { return "HTMLSelectElement"; }
}
