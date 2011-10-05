// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitTransitionEventWrappingImplementation extends _EventWrappingImplementation implements WebKitTransitionEvent {
  _WebKitTransitionEventWrappingImplementation() : super() {}

  static create__WebKitTransitionEventWrappingImplementation() native {
    return new _WebKitTransitionEventWrappingImplementation();
  }

  num get elapsedTime() { return _get__WebKitTransitionEvent_elapsedTime(this); }
  static num _get__WebKitTransitionEvent_elapsedTime(var _this) native;

  String get propertyName() { return _get__WebKitTransitionEvent_propertyName(this); }
  static String _get__WebKitTransitionEvent_propertyName(var _this) native;

  void initWebKitTransitionEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String propertyNameArg = null, num elapsedTimeArg = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (propertyNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitTransitionEvent(this);
              return;
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (propertyNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitTransitionEvent_2(this, typeArg);
              return;
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (propertyNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitTransitionEvent_3(this, typeArg, canBubbleArg);
              return;
            }
          }
        } else {
          if (propertyNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitTransitionEvent_4(this, typeArg, canBubbleArg, cancelableArg);
              return;
            }
          } else {
            if (elapsedTimeArg === null) {
              _initWebKitTransitionEvent_5(this, typeArg, canBubbleArg, cancelableArg, propertyNameArg);
              return;
            } else {
              _initWebKitTransitionEvent_6(this, typeArg, canBubbleArg, cancelableArg, propertyNameArg, elapsedTimeArg);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initWebKitTransitionEvent(receiver) native;
  static void _initWebKitTransitionEvent_2(receiver, typeArg) native;
  static void _initWebKitTransitionEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initWebKitTransitionEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initWebKitTransitionEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, propertyNameArg) native;
  static void _initWebKitTransitionEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, propertyNameArg, elapsedTimeArg) native;

  String get typeName() { return "WebKitTransitionEvent"; }
}
