// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLUListElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLUListElement {
  _HTMLUListElementWrappingImplementation() : super() {}

  static create__HTMLUListElementWrappingImplementation() native {
    return new _HTMLUListElementWrappingImplementation();
  }

  bool get compact() { return _get_compact(this); }
  static bool _get_compact(var _this) native;

  void set compact(bool value) { _set_compact(this, value); }
  static void _set_compact(var _this, bool value) native;

  String get type() { return _get_type(this); }
  static String _get_type(var _this) native;

  void set type(String value) { _set_type(this, value); }
  static void _set_type(var _this, String value) native;

  String get typeName() { return "HTMLUListElement"; }
}
