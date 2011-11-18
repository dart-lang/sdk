// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PopStateEventWrappingImplementation extends _EventWrappingImplementation implements PopStateEvent {
  _PopStateEventWrappingImplementation() : super() {}

  static create__PopStateEventWrappingImplementation() native {
    return new _PopStateEventWrappingImplementation();
  }

  Object get state() { return _get_state(this); }
  static Object _get_state(var _this) native;

  void initPopStateEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object stateArg) {
    _initPopStateEvent(this, typeArg, canBubbleArg, cancelableArg, stateArg);
    return;
  }
  static void _initPopStateEvent(receiver, typeArg, canBubbleArg, cancelableArg, stateArg) native;

  String get typeName() { return "PopStateEvent"; }
}
