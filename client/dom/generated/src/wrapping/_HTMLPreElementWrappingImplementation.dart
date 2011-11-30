// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLPreElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLPreElement {
  _HTMLPreElementWrappingImplementation() : super() {}

  static create__HTMLPreElementWrappingImplementation() native {
    return new _HTMLPreElementWrappingImplementation();
  }

  int get width() { return _get_width(this); }
  static int _get_width(var _this) native;

  void set width(int value) { _set_width(this, value); }
  static void _set_width(var _this, int value) native;

  bool get wrap() { return _get_wrap(this); }
  static bool _get_wrap(var _this) native;

  void set wrap(bool value) { _set_wrap(this, value); }
  static void _set_wrap(var _this, bool value) native;

  String get typeName() { return "HTMLPreElement"; }
}
