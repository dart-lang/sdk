// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLMapElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLMapElement {
  _HTMLMapElementWrappingImplementation() : super() {}

  static create__HTMLMapElementWrappingImplementation() native {
    return new _HTMLMapElementWrappingImplementation();
  }

  HTMLCollection get areas() { return _get_areas(this); }
  static HTMLCollection _get_areas(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  void set name(String value) { _set_name(this, value); }
  static void _set_name(var _this, String value) native;

  String get typeName() { return "HTMLMapElement"; }
}
