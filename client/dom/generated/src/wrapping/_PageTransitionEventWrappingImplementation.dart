// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _PageTransitionEventWrappingImplementation extends _EventWrappingImplementation implements PageTransitionEvent {
  _PageTransitionEventWrappingImplementation() : super() {}

  static create__PageTransitionEventWrappingImplementation() native {
    return new _PageTransitionEventWrappingImplementation();
  }

  bool get persisted() { return _get__PageTransitionEvent_persisted(this); }
  static bool _get__PageTransitionEvent_persisted(var _this) native;

  void initPageTransitionEvent(String typeArg, bool canBubbleArg, bool cancelableArg, bool persisted) {
    _initPageTransitionEvent(this, typeArg, canBubbleArg, cancelableArg, persisted);
    return;
  }
  static void _initPageTransitionEvent(receiver, typeArg, canBubbleArg, cancelableArg, persisted) native;

  String get typeName() { return "PageTransitionEvent"; }
}
