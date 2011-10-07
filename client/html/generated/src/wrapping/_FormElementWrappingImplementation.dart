// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class FormElementWrappingImplementation extends ElementWrappingImplementation implements FormElement {
  FormElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get acceptCharset() { return _ptr.acceptCharset; }

  void set acceptCharset(String value) { _ptr.acceptCharset = value; }

  String get action() { return _ptr.action; }

  void set action(String value) { _ptr.action = value; }

  String get autocomplete() { return _ptr.autocomplete; }

  void set autocomplete(String value) { _ptr.autocomplete = value; }

  String get encoding() { return _ptr.encoding; }

  void set encoding(String value) { _ptr.encoding = value; }

  String get enctype() { return _ptr.enctype; }

  void set enctype(String value) { _ptr.enctype = value; }

  int get length() { return _ptr.length; }

  String get method() { return _ptr.method; }

  void set method(String value) { _ptr.method = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  bool get noValidate() { return _ptr.noValidate; }

  void set noValidate(bool value) { _ptr.noValidate = value; }

  String get target() { return _ptr.target; }

  void set target(String value) { _ptr.target = value; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void reset() {
    _ptr.reset();
    return;
  }

  void submit() {
    _ptr.submit();
    return;
  }
}
