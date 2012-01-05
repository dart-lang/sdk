// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLLabelElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLLabelElement {
  _HTMLLabelElementWrappingImplementation() : super() {}

  static create__HTMLLabelElementWrappingImplementation() native {
    return new _HTMLLabelElementWrappingImplementation();
  }

  String get accessKey() { return _get_accessKey(this); }
  static String _get_accessKey(var _this) native;

  void set accessKey(String value) { _set_accessKey(this, value); }
  static void _set_accessKey(var _this, String value) native;

  HTMLElement get control() { return _get_control(this); }
  static HTMLElement _get_control(var _this) native;

  HTMLFormElement get form() { return _get_form(this); }
  static HTMLFormElement _get_form(var _this) native;

  String get htmlFor() { return _get_htmlFor(this); }
  static String _get_htmlFor(var _this) native;

  void set htmlFor(String value) { _set_htmlFor(this, value); }
  static void _set_htmlFor(var _this, String value) native;

  String get typeName() { return "HTMLLabelElement"; }
}
