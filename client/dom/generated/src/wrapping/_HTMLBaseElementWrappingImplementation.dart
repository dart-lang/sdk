// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLBaseElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLBaseElement {
  _HTMLBaseElementWrappingImplementation() : super() {}

  static create__HTMLBaseElementWrappingImplementation() native {
    return new _HTMLBaseElementWrappingImplementation();
  }

  String get href() { return _get_href(this); }
  static String _get_href(var _this) native;

  void set href(String value) { _set_href(this, value); }
  static void _set_href(var _this, String value) native;

  String get target() { return _get_target(this); }
  static String _get_target(var _this) native;

  void set target(String value) { _set_target(this, value); }
  static void _set_target(var _this, String value) native;

  String get typeName() { return "HTMLBaseElement"; }
}
