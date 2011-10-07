// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class TextAreaElementWrappingImplementation extends ElementWrappingImplementation implements TextAreaElement {
  TextAreaElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get accessKey() { return _ptr.accessKey; }

  void set accessKey(String value) { _ptr.accessKey = value; }

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  int get cols() { return _ptr.cols; }

  void set cols(int value) { _ptr.cols = value; }

  String get defaultValue() { return _ptr.defaultValue; }

  void set defaultValue(String value) { _ptr.defaultValue = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get maxLength() { return _ptr.maxLength; }

  void set maxLength(int value) { _ptr.maxLength = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get placeholder() { return _ptr.placeholder; }

  void set placeholder(String value) { _ptr.placeholder = value; }

  bool get readOnly() { return _ptr.readOnly; }

  void set readOnly(bool value) { _ptr.readOnly = value; }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get rows() { return _ptr.rows; }

  void set rows(int value) { _ptr.rows = value; }

  String get selectionDirection() { return _ptr.selectionDirection; }

  void set selectionDirection(String value) { _ptr.selectionDirection = value; }

  int get selectionEnd() { return _ptr.selectionEnd; }

  void set selectionEnd(int value) { _ptr.selectionEnd = value; }

  int get selectionStart() { return _ptr.selectionStart; }

  void set selectionStart(int value) { _ptr.selectionStart = value; }

  int get textLength() { return _ptr.textLength; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  String get wrap() { return _ptr.wrap; }

  void set wrap(String value) { _ptr.wrap = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void select() {
    _ptr.select();
    return;
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  void setSelectionRange(int start, int end, [String direction = null]) {
    if (direction === null) {
      _ptr.setSelectionRange(start, end);
      return;
    } else {
      _ptr.setSelectionRange(start, end, direction);
      return;
    }
  }
}
