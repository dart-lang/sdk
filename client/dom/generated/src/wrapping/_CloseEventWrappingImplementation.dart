// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _CloseEventWrappingImplementation extends _EventWrappingImplementation implements CloseEvent {
  _CloseEventWrappingImplementation() : super() {}

  static create__CloseEventWrappingImplementation() native {
    return new _CloseEventWrappingImplementation();
  }

  int get code() { return _get__CloseEvent_code(this); }
  static int _get__CloseEvent_code(var _this) native;

  String get reason() { return _get__CloseEvent_reason(this); }
  static String _get__CloseEvent_reason(var _this) native;

  bool get wasClean() { return _get__CloseEvent_wasClean(this); }
  static bool _get__CloseEvent_wasClean(var _this) native;

  void initCloseEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, bool wasCleanArg = null, int codeArg = null, String reasonArg = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (wasCleanArg === null) {
            if (codeArg === null) {
              if (reasonArg === null) {
                _initCloseEvent(this);
                return;
              }
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (wasCleanArg === null) {
            if (codeArg === null) {
              if (reasonArg === null) {
                _initCloseEvent_2(this, typeArg);
                return;
              }
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (wasCleanArg === null) {
            if (codeArg === null) {
              if (reasonArg === null) {
                _initCloseEvent_3(this, typeArg, canBubbleArg);
                return;
              }
            }
          }
        } else {
          if (wasCleanArg === null) {
            if (codeArg === null) {
              if (reasonArg === null) {
                _initCloseEvent_4(this, typeArg, canBubbleArg, cancelableArg);
                return;
              }
            }
          } else {
            if (codeArg === null) {
              if (reasonArg === null) {
                _initCloseEvent_5(this, typeArg, canBubbleArg, cancelableArg, wasCleanArg);
                return;
              }
            } else {
              if (reasonArg === null) {
                _initCloseEvent_6(this, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg);
                return;
              } else {
                _initCloseEvent_7(this, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg, reasonArg);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initCloseEvent(receiver) native;
  static void _initCloseEvent_2(receiver, typeArg) native;
  static void _initCloseEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initCloseEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initCloseEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, wasCleanArg) native;
  static void _initCloseEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg) native;
  static void _initCloseEvent_7(receiver, typeArg, canBubbleArg, cancelableArg, wasCleanArg, codeArg, reasonArg) native;

  String get typeName() { return "CloseEvent"; }
}
