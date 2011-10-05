// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PopStateEventWrappingImplementation extends _EventWrappingImplementation implements PopStateEvent {
  _PopStateEventWrappingImplementation() : super() {}

  static create__PopStateEventWrappingImplementation() native {
    return new _PopStateEventWrappingImplementation();
  }

  Object get state() { return _get__PopStateEvent_state(this); }
  static Object _get__PopStateEvent_state(var _this) native;

  void initPopStateEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, Object stateArg = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (stateArg === null) {
            _initPopStateEvent(this);
            return;
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (stateArg === null) {
            _initPopStateEvent_2(this, typeArg);
            return;
          }
        }
      } else {
        if (cancelableArg === null) {
          if (stateArg === null) {
            _initPopStateEvent_3(this, typeArg, canBubbleArg);
            return;
          }
        } else {
          if (stateArg === null) {
            _initPopStateEvent_4(this, typeArg, canBubbleArg, cancelableArg);
            return;
          } else {
            _initPopStateEvent_5(this, typeArg, canBubbleArg, cancelableArg, stateArg);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initPopStateEvent(receiver) native;
  static void _initPopStateEvent_2(receiver, typeArg) native;
  static void _initPopStateEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initPopStateEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initPopStateEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, stateArg) native;

  String get typeName() { return "PopStateEvent"; }
}
