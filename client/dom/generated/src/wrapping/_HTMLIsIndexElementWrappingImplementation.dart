// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLIsIndexElementWrappingImplementation extends _HTMLInputElementWrappingImplementation implements HTMLIsIndexElement {
  _HTMLIsIndexElementWrappingImplementation() : super() {}

  static create__HTMLIsIndexElementWrappingImplementation() native {
    return new _HTMLIsIndexElementWrappingImplementation();
  }

  HTMLFormElement get form() { return _get_form_HTMLIsIndexElement(this); }
  static HTMLFormElement _get_form_HTMLIsIndexElement(var _this) native;

  String get prompt() { return _get_prompt(this); }
  static String _get_prompt(var _this) native;

  void set prompt(String value) { _set_prompt(this, value); }
  static void _set_prompt(var _this, String value) native;

  String get typeName() { return "HTMLIsIndexElement"; }
}
