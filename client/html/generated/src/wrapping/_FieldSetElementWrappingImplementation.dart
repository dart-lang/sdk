// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FieldSetElementWrappingImplementation extends ElementWrappingImplementation implements FieldSetElement {
  FieldSetElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

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

  String get typeName() { return "FieldSetElement"; }
}
