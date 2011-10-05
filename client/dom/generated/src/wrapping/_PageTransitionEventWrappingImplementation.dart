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

  void initPageTransitionEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, bool persisted = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (persisted === null) {
            _initPageTransitionEvent(this);
            return;
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (persisted === null) {
            _initPageTransitionEvent_2(this, typeArg);
            return;
          }
        }
      } else {
        if (cancelableArg === null) {
          if (persisted === null) {
            _initPageTransitionEvent_3(this, typeArg, canBubbleArg);
            return;
          }
        } else {
          if (persisted === null) {
            _initPageTransitionEvent_4(this, typeArg, canBubbleArg, cancelableArg);
            return;
          } else {
            _initPageTransitionEvent_5(this, typeArg, canBubbleArg, cancelableArg, persisted);
            return;
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initPageTransitionEvent(receiver) native;
  static void _initPageTransitionEvent_2(receiver, typeArg) native;
  static void _initPageTransitionEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initPageTransitionEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initPageTransitionEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, persisted) native;

  String get typeName() { return "PageTransitionEvent"; }
}
