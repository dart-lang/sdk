// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitAnimationEventWrappingImplementation extends _EventWrappingImplementation implements WebKitAnimationEvent {
  _WebKitAnimationEventWrappingImplementation() : super() {}

  static create__WebKitAnimationEventWrappingImplementation() native {
    return new _WebKitAnimationEventWrappingImplementation();
  }

  String get animationName() { return _get__WebKitAnimationEvent_animationName(this); }
  static String _get__WebKitAnimationEvent_animationName(var _this) native;

  num get elapsedTime() { return _get__WebKitAnimationEvent_elapsedTime(this); }
  static num _get__WebKitAnimationEvent_elapsedTime(var _this) native;

  void initWebKitAnimationEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String animationNameArg = null, num elapsedTimeArg = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (animationNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitAnimationEvent(this);
              return;
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (animationNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitAnimationEvent_2(this, typeArg);
              return;
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (animationNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitAnimationEvent_3(this, typeArg, canBubbleArg);
              return;
            }
          }
        } else {
          if (animationNameArg === null) {
            if (elapsedTimeArg === null) {
              _initWebKitAnimationEvent_4(this, typeArg, canBubbleArg, cancelableArg);
              return;
            }
          } else {
            if (elapsedTimeArg === null) {
              _initWebKitAnimationEvent_5(this, typeArg, canBubbleArg, cancelableArg, animationNameArg);
              return;
            } else {
              _initWebKitAnimationEvent_6(this, typeArg, canBubbleArg, cancelableArg, animationNameArg, elapsedTimeArg);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initWebKitAnimationEvent(receiver) native;
  static void _initWebKitAnimationEvent_2(receiver, typeArg) native;
  static void _initWebKitAnimationEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initWebKitAnimationEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initWebKitAnimationEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, animationNameArg) native;
  static void _initWebKitAnimationEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, animationNameArg, elapsedTimeArg) native;

  String get typeName() { return "WebKitAnimationEvent"; }
}
