// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HTMLDListElementWrappingImplementation extends _HTMLElementWrappingImplementation implements HTMLDListElement {
  _HTMLDListElementWrappingImplementation() : super() {}

  static create__HTMLDListElementWrappingImplementation() native {
    return new _HTMLDListElementWrappingImplementation();
  }

  bool get compact() { return _get_compact(this); }
  static bool _get_compact(var _this) native;

  void set compact(bool value) { _set_compact(this, value); }
  static void _set_compact(var _this, bool value) native;

  String get typeName() { return "HTMLDListElement"; }
}
