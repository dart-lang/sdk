// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CompositionEventWrappingImplementation extends _UIEventWrappingImplementation implements CompositionEvent {
  _CompositionEventWrappingImplementation() : super() {}

  static create__CompositionEventWrappingImplementation() native {
    return new _CompositionEventWrappingImplementation();
  }

  String get data() { return _get__CompositionEvent_data(this); }
  static String _get__CompositionEvent_data(var _this) native;

  void initCompositionEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, DOMWindow viewArg = null, String dataArg = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (viewArg === null) {
            if (dataArg === null) {
              _initCompositionEvent(this);
              return;
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (viewArg === null) {
            if (dataArg === null) {
              _initCompositionEvent_2(this, typeArg);
              return;
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (viewArg === null) {
            if (dataArg === null) {
              _initCompositionEvent_3(this, typeArg, canBubbleArg);
              return;
            }
          }
        } else {
          if (viewArg === null) {
            if (dataArg === null) {
              _initCompositionEvent_4(this, typeArg, canBubbleArg, cancelableArg);
              return;
            }
          } else {
            if (dataArg === null) {
              _initCompositionEvent_5(this, typeArg, canBubbleArg, cancelableArg, viewArg);
              return;
            } else {
              _initCompositionEvent_6(this, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initCompositionEvent(receiver) native;
  static void _initCompositionEvent_2(receiver, typeArg) native;
  static void _initCompositionEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initCompositionEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initCompositionEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, viewArg) native;
  static void _initCompositionEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native;

  String get typeName() { return "CompositionEvent"; }
}
