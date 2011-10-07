// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ObjectElementWrappingImplementation extends ElementWrappingImplementation implements ObjectElement {
  ObjectElementWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  String get align() { return _ptr.align; }

  void set align(String value) { _ptr.align = value; }

  String get archive() { return _ptr.archive; }

  void set archive(String value) { _ptr.archive = value; }

  String get border() { return _ptr.border; }

  void set border(String value) { _ptr.border = value; }

  String get code() { return _ptr.code; }

  void set code(String value) { _ptr.code = value; }

  String get codeBase() { return _ptr.codeBase; }

  void set codeBase(String value) { _ptr.codeBase = value; }

  String get codeType() { return _ptr.codeType; }

  void set codeType(String value) { _ptr.codeType = value; }

  Document get contentDocument() { return LevelDom.wrapDocument(_ptr.contentDocument); }

  String get data() { return _ptr.data; }

  void set data(String value) { _ptr.data = value; }

  bool get declare() { return _ptr.declare; }

  void set declare(bool value) { _ptr.declare = value; }

  FormElement get form() { return LevelDom.wrapFormElement(_ptr.form); }

  String get height() { return _ptr.height; }

  void set height(String value) { _ptr.height = value; }

  int get hspace() { return _ptr.hspace; }

  void set hspace(int value) { _ptr.hspace = value; }

  String get name() { return _ptr.name; }

  void set name(String value) { _ptr.name = value; }

  String get standby() { return _ptr.standby; }

  void set standby(String value) { _ptr.standby = value; }

  String get type() { return _ptr.type; }

  void set type(String value) { _ptr.type = value; }

  String get useMap() { return _ptr.useMap; }

  void set useMap(String value) { _ptr.useMap = value; }

  String get validationMessage() { return _ptr.validationMessage; }

  ValidityState get validity() { return LevelDom.wrapValidityState(_ptr.validity); }

  int get vspace() { return _ptr.vspace; }

  void set vspace(int value) { _ptr.vspace = value; }

  String get width() { return _ptr.width; }

  void set width(String value) { _ptr.width = value; }

  bool get willValidate() { return _ptr.willValidate; }

  bool checkValidity() {
    return _ptr.checkValidity();
  }

  void setCustomValidity(String error) {
    _ptr.setCustomValidity(error);
    return;
  }
}
