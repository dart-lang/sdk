// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OverflowEventWrappingImplementation extends _EventWrappingImplementation implements OverflowEvent {
  _OverflowEventWrappingImplementation() : super() {}

  static create__OverflowEventWrappingImplementation() native {
    return new _OverflowEventWrappingImplementation();
  }

  bool get horizontalOverflow() { return _get_horizontalOverflow(this); }
  static bool _get_horizontalOverflow(var _this) native;

  int get orient() { return _get_orient(this); }
  static int _get_orient(var _this) native;

  bool get verticalOverflow() { return _get_verticalOverflow(this); }
  static bool _get_verticalOverflow(var _this) native;

  void initOverflowEvent(int orient, bool horizontalOverflow, bool verticalOverflow) {
    _initOverflowEvent(this, orient, horizontalOverflow, verticalOverflow);
    return;
  }
  static void _initOverflowEvent(receiver, orient, horizontalOverflow, verticalOverflow) native;

  String get typeName() { return "OverflowEvent"; }
}
