// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLFieldSetElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLFieldSetElement {
  _HTMLFieldSetElementWrappingImplementation() : super() {}

  static create__HTMLFieldSetElementWrappingImplementation() native {
    return new _HTMLFieldSetElementWrappingImplementation();
  }

  HTMLFormElement get form() { return _get__HTMLFieldSetElement_form(this); }
  static HTMLFormElement _get__HTMLFieldSetElement_form(var _this) native;

  String get validationMessage() { return _get__HTMLFieldSetElement_validationMessage(this); }
  static String _get__HTMLFieldSetElement_validationMessage(var _this) native;

  ValidityState get validity() { return _get__HTMLFieldSetElement_validity(this); }
  static ValidityState _get__HTMLFieldSetElement_validity(var _this) native;

  bool get willValidate() { return _get__HTMLFieldSetElement_willValidate(this); }
  static bool _get__HTMLFieldSetElement_willValidate(var _this) native;

  bool checkValidity() {
    return _checkValidity(this);
  }
  static bool _checkValidity(receiver) native;

  void setCustomValidity(String error) {
    _setCustomValidity(this, error);
    return;
  }
  static void _setCustomValidity(receiver, error) native;

  String get typeName() { return "HTMLFieldSetElement"; }
}
