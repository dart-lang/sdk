// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLMetaElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLMetaElement {
  _HTMLMetaElementWrappingImplementation() : super() {}

  static create__HTMLMetaElementWrappingImplementation() native {
    return new _HTMLMetaElementWrappingImplementation();
  }

  String get content() { return _get_content(this); }
  static String _get_content(var _this) native;

  void set content(String value) { _set_content(this, value); }
  static void _set_content(var _this, String value) native;

  String get httpEquiv() { return _get_httpEquiv(this); }
  static String _get_httpEquiv(var _this) native;

  void set httpEquiv(String value) { _set_httpEquiv(this, value); }
  static void _set_httpEquiv(var _this, String value) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  String get scheme() { return _get_scheme(this); }
  static String _get_scheme(var _this) native;

  void set scheme(String value) { _set_scheme(this, value); }
  static void _set_scheme(var _this, String value) native;

  String get typeName() { return "HTMLMetaElement"; }
}
