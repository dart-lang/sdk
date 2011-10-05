// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class SelectElementWrappingImplementation extends ElementWrappingImplementation implements SelectElement {
  SelectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get autofocus() { return _ptr.autofocus; }

  void set autofocus(bool value) { _ptr.autofocus = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  ElementList get labels() { return LevelDom.wrapElementList(_ptr.labels); }

  int get length() { return _ptr.length; }

  void set length(int value) { _ptr.length = value; }

  bool get multiple() { return _ptr.multiple; }

  void set multiple(bool value) { _ptr.multiple = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  ElementList get options() { return LevelDom.wrapElementList(_ptr.options); }

  bool get required() { return _ptr.required; }

  void set required(bool value) { _ptr.required = value; }

  int get selectedIndex() { return _ptr.selectedIndex; }

  void set selectedIndex(int value) { _ptr.selectedIndex = value; }

  int get size() { return _ptr.size; }

  void set size(int value) { _ptr.size = value; }

  String get type() { return _ptr.type; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }

  bool get willValidate() { return _ptr.willValidate; }

  void add(Element element, Element before) {
    _ptr.add(LevelDom.unwrap(element), LevelDom.unwrap(before));
    return;
  }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  Node item(int index) {
    return LevelDom.wrapNode(_ptr.item(index));
  }

  Node namedItem(String name) {
    return LevelDom.wrapNode(_ptr.namedItem(name));
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }

  String get typeName() { return "SelectElement"; }
}
