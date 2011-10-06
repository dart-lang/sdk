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

  void initWebKitTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, String propertyNameArg, num elapsedTimeArg) {
    _initWebKitTransitionEvent(this, typeArg, canBubbleArg, cancelableArg, propertyNameArg, elapsedTimeArg);
    return;
  }
  static void _initWebKitTransitionEvent(receiver, typeArg, canBubbleArg, cancelableArg, propertyNameArg, elapsedTimeArg) native;

  String get typeName() { return "WebKitTransitionEvent"; }
}
