// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AttrWrappingImplementation extends _NodeWrappingImplementation implements Attr {
  _AttrWrappingImplementation() : super() {}

  static create__AttrWrappingImplementation() native {
    return new _AttrWrappingImplementation();
  }

  bool get isId() { return _get_isId(this); }
  static bool _get_isId(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  Element get ownerElement() { return _get_ownerElement(this); }
  static Element _get_ownerElement(var _this) native;

  bool get specified() { return _get_specified(this); }
  static bool _get_specified(var _this) native;

  String get value() { return _get_value(this); }
  static String _get_value(var _this) native;

  void set value(String value) { _set_value(this, value); }
  static void _set_value(var _this, String value) native;

  String get typeName() { return "Attr"; }
}
