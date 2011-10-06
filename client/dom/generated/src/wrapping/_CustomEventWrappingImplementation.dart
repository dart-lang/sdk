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

  void initCustomEvent(String typeArg, bool canBubbleArg, bool cancelableArg, Object detailArg) {
    _initCustomEvent(this, typeArg, canBubbleArg, cancelableArg, detailArg);
    return;
  }
  static void _initCustomEvent(receiver, typeArg, canBubbleArg, cancelableArg, detailArg) native;

  String get typeName() { return "CustomEvent"; }
}
