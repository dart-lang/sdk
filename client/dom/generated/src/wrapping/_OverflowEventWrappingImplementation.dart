// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _OverflowEventWrappingImplementation extends _EventWrappingImplementation implements OverflowEvent {
  _OverflowEventWrappingImplementation() : super() {}

  static create__OverflowEventWrappingImplementation() native {
    return new _OverflowEventWrappingImplementation();
  }

  bool get horizontalOverflow() { return _get__OverflowEvent_horizontalOverflow(this); }
  static bool _get__OverflowEvent_horizontalOverflow(var _this) native;

  int get orient() { return _get__OverflowEvent_orient(this); }
  static int _get__OverflowEvent_orient(var _this) native;

  bool get verticalOverflow() { return _get__OverflowEvent_verticalOverflow(this); }
  static bool _get__OverflowEvent_verticalOverflow(var _this) native;

  void initOverflowEvent(int orient = null, bool horizontalOverflow = null, bool verticalOverflow = null) {
    if (orient === null) {
      if (horizontalOverflow === null) {
        if (verticalOverflow === null) {
          _initOverflowEvent(this);
          return;
        }
      }
    } else {
      if (horizontalOverflow === null) {
        if (verticalOverflow === null) {
          _initOverflowEvent_2(this, orient);
          return;
        }
      } else {
        if (verticalOverflow === null) {
          _initOverflowEvent_3(this, orient, horizontalOverflow);
          return;
        } else {
          _initOverflowEvent_4(this, orient, horizontalOverflow, verticalOverflow);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initOverflowEvent(receiver) native;
  static void _initOverflowEvent_2(receiver, orient) native;
  static void _initOverflowEvent_3(receiver, orient, horizontalOverflow) native;
  static void _initOverflowEvent_4(receiver, orient, horizontalOverflow, verticalOverflow) native;

  String get typeName() { return "OverflowEvent"; }
}
