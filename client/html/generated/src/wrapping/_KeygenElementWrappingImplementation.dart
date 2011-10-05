// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class KeygenElementWrappingImplementation extends ElementWrappingImplementation implements KeygenElement {
  KeygenElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  String get challenge() { return _ptr.challenge; }

  void set challenge(String value) { _ptr.challenge = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get keytype() { return _ptr.keytype; }

  void set keytype(String value) { _ptr.keytype = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  String get typeName() { return "KeygenElement"; }
}
