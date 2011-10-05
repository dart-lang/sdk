// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ButtonElementWrappingImplementation extends ElementWrappingImplementation implements ButtonElement {
  ButtonElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get formAction() { return _ptr.formAction; }

  void set formAction(String value) { _ptr.formAction = value; }

  String get formEnctype() { return _ptr.formEnctype; }

  void set formEnctype(String value) { _ptr.formEnctype = value; }

  String get formMethod() { return _ptr.formMethod; }

  void set formMethod(String value) { _ptr.formMethod = value; }

  bool get formNoValidate() { return _ptr.formNoValidate; }

  void set formNoValidate(bool value) { _ptr.formNoValidate = value; }

  String get formTarget() { return _ptr.formTarget; }

  void set formTarget(String value) { _ptr.formTarget = value; }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void click() {
    _ptr.click();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  String get typeName() { return "ButtonElement"; }
}
