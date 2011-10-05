// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _TextEventWrappingImplementation extends _UIEventWrappingImplementation implements TextEvent {
  _TextEventWrappingImplementation() : super() {}

  static create__TextEventWrappingImplementation() native {
    return new _TextEventWrappingImplementation();
  }

  String get data() { return _get__TextEvent_data(this); }
  static String _get__TextEvent_data(var _this) native;

  void initTextEvent(String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, DOMWindow viewArg = null, String dataArg = null) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (viewArg === null) {
            if (dataArg === null) {
              _initTextEvent(this);
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
              _initTextEvent_2(this, typeArg);
              return;
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (viewArg === null) {
            if (dataArg === null) {
              _initTextEvent_3(this, typeArg, canBubbleArg);
              return;
            }
          }
        } else {
          if (viewArg === null) {
            if (dataArg === null) {
              _initTextEvent_4(this, typeArg, canBubbleArg, cancelableArg);
              return;
            }
          } else {
            if (dataArg === null) {
              _initTextEvent_5(this, typeArg, canBubbleArg, cancelableArg, viewArg);
              return;
            } else {
              _initTextEvent_6(this, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initTextEvent(receiver) native;
  static void _initTextEvent_2(receiver, typeArg) native;
  static void _initTextEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initTextEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initTextEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, viewArg) native;
  static void _initTextEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, viewArg, dataArg) native;

  String get typeName() { return "TextEvent"; }
}
