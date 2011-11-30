// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLSourceElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLSourceElement {
  _HTMLSourceElementWrappingImplementation() : super() {}

  static create__HTMLSourceElementWrappingImplementation() native {
    return new _HTMLSourceElementWrappingImplementation();
  }

  String get media() { return _get_media(this); }
  static String _get_media(var _this) native;

  void set media(String value) { _set_media(this, value); }
  static void _set_media(var _this, String value) native;

  String get src() { return _get_src(this); }
  static String _get_src(var _this) native;

  void set src(String value) { _set_src(this, value); }
  static void _set_src(var _this, String value) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  String get typeName() { return "HTMLSourceElement"; }
}
