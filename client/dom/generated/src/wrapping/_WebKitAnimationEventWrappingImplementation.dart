// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WebKitAnimationEventWrappingImplementation extends _EventWrappingImplementation implements WebKitAnimationEvent {
  _WebKitAnimationEventWrappingImplementation() : super() {}

  static create__WebKitAnimationEventWrappingImplementation() native {
    return new _WebKitAnimationEventWrappingImplementation();
  }

  String get animationName() { return _get_animationName(this); }
  static String _get_animationName(var _this) native;

  num get elapsedTime() { return _get_elapsedTime(this); }
  static num _get_elapsedTime(var _this) native;

  void initWebKitAnimationEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String animationNameArg, num elapsedTimeArg) {
    _initWebKitAnimationEvent(this, typeArg, canBubbleArg, cancelableArg, animationNameArg, elapsedTimeArg);
    return;
  }
  static void _initWebKitAnimationEvent(receiver, typeArg, canBubbleArg, cancelableArg, animationNameArg, elapsedTimeArg) native;

  String get typeName() { return "WebKitAnimationEvent"; }
}
