// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OutputElementWrappingImplementation extends ElementWrappingImplementation implements OutputElement {
  OutputElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  DOMSettableTokenList get htmlFor() { return LevelDom.wrapDOMSettableTokenList(_ptr.htmlFor); }

  void set htmlFor(DOMSettableTokenList value) { _ptr.htmlFor = LevelDom.unwrap(value); }

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

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  String get typeName() { return "OutputElement"; }
}
