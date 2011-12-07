// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class OptionElementWrappingImplementation extends ElementWrappingImplementation implements OptionElement {
  OptionElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  bool get defaultSelected() { return _ptr.defaultSelected; }

  void set defaultSelected(bool value) { _ptr.defaultSelected = value; }

  bool get disabled() { return _ptr.disabled; }

  void set disabled(bool value) { _ptr.disabled = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  int get index() { return _ptr.index; }

  String get label() { return _ptr.label; }

  void set label(String value) { _ptr.label = value; }

  bool get selected() { return _ptr.selected; }

  void set selected(bool value) { _ptr.selected = value; }

  String get text() { return _ptr.text; }

  void set text(String value) { _ptr.text = value; }

  String get value() { return _ptr.value; }

  void set value(String value) { _ptr.value = value; }
}
