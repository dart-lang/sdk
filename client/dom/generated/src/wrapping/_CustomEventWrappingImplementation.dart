// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CustomEventWrappingImplementation extends _EventWrappingImplementation implements CustomEvent {
  _CustomEventWrappingImplementation() : super() {}

  static create__CustomEventWrappingImplementation() native {
    return new _CustomEventWrappingImplementation();
  }

  Object get detail() { return _get__CustomEvent_detail(this); }
  static Object _get__CustomEvent_detail(var _this) native;

  void initCustomEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, Object detailArg = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (detailArg === null) {
            _initCustomEvent(this);
            return;
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (detailArg === null) {
            _initCustomEvent_2(this, typeArg);
            return;
          }
        }
      } else {
        if (cancelableArg === null) {
          if (detailArg === null) {
            _initCustomEvent_3(this, typeArg, canBubbleArg);
            return;
          }
        } else {
          if (detailArg === null) {
            _initCustomEvent_4(this, typeArg, canBubbleArg, cancelableArg);
            return;
          } else {
            _initCustomEvent_5(this, typeArg, canBubbleArg, cancelableArg, detailArg);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initCustomEvent(receiver) native;
  static void _initCustomEvent_2(receiver, typeArg) native;
  static void _initCustomEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initCustomEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initCustomEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, detailArg) native;

  String get typeName() { return "CustomEvent"; }
}
