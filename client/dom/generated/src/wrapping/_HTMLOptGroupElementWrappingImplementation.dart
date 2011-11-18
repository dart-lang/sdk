// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLOptGroupElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLOptGroupElement {
  _HTMLOptGroupElementWrappingImplementation() : super() {}

  static create__HTMLOptGroupElementWrappingImplementation() native {
    return new _HTMLOptGroupElementWrappingImplementation();
  }

  bool get disabled() { return _get_disabled(this); }
  static bool _get_disabled(var _this) native;

  void set disabled(bool value) { _set_disabled(this, value); }
  static void _set_disabled(var _this, bool value) native;

  String get label() { return _get_label(this); }
  static String _get_label(var _this) native;

  void set label(String value) { _set_label(this, value); }
  static void _set_label(var _this, String value) native;

  String get typeName() { return "HTMLOptGroupElement"; }
}
