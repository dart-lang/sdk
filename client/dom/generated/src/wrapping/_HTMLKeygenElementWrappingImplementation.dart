// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLKeygenElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLKeygenElement {
  _HTMLKeygenElementWrappingImplementation() : super() {}

  static create__HTMLKeygenElementWrappingImplementation() native {
    return new _HTMLKeygenElementWrappingImplementation();
  }

  bool get autofocus() { return _get__HTMLKeygenElement_autofocus(this); }
  static bool _get__HTMLKeygenElement_autofocus(var _this) native;

  void set autofocus(bool value) { _set__HTMLKeygenElement_autofocus(this, value); }
  static void _set__HTMLKeygenElement_autofocus(var _this, bool value) native;

  String get challenge() { return _get__HTMLKeygenElement_challenge(this); }
  static String _get__HTMLKeygenElement_challenge(var _this) native;

  void set challenge(String value) { _set__HTMLKeygenElement_challenge(this, value); }
  static void _set__HTMLKeygenElement_challenge(var _this, String value) native;

  bool get disabled() { return _get__HTMLKeygenElement_disabled(this); }
  static bool _get__HTMLKeygenElement_disabled(var _this) native;

  void set disabled(bool value) { _set__HTMLKeygenElement_disabled(this, value); }
  static void _set__HTMLKeygenElement_disabled(var _this, bool value) native;

  HTMLFormElement get form() { return _get__HTMLKeygenElement_form(this); }
  static HTMLFormElement _get__HTMLKeygenElement_form(var _this) native;

  String get keytype() { return _get__HTMLKeygenElement_keytype(this); }
  static String _get__HTMLKeygenElement_keytype(var _this) native;

  void set keytype(String value) { _set__HTMLKeygenElement_keytype(this, value); }
  static void _set__HTMLKeygenElement_keytype(var _this, String value) native;

  NodeList get labels() { return _get__HTMLKeygenElement_labels(this); }
  static NodeList _get__HTMLKeygenElement_labels(var _this) native;

  String get name() { return _get__HTMLKeygenElement_name(this); }
  static String _get__HTMLKeygenElement_name(var _this) native;

  void set name(String value) { _set__HTMLKeygenElement_name(this, value); }
  static void _set__HTMLKeygenElement_name(var _this, String value) native;

  String get type() { return _get__HTMLKeygenElement_type(this); }
  static String _get__HTMLKeygenElement_type(var _this) native;

  String get validationMessage() { return _get__HTMLKeygenElement_validationMessage(this); }
  static String _get__HTMLKeygenElement_validationMessage(var _this) native;

  ValidityState get validity() { return _get__HTMLKeygenElement_validity(this); }
  static ValidityState _get__HTMLKeygenElement_validity(var _this) native;

  bool get willValidate() { return _get__HTMLKeygenElement_willValidate(this); }
  static bool _get__HTMLKeygenElement_willValidate(var _this) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  void setCustomValidity(String error) {
    _setCustomValidity(this, error);
    return;
  }
  static void _setCustomValidity(receiver, error) native;

  String get typeName() { return "HTMLKeygenElement"; }
}
