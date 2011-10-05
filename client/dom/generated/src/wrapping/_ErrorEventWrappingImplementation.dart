// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ErrorEventWrappingImplementation extends _EventWrappingImplementation implements ErrorEvent {
  _ErrorEventWrappingImplementation() : super() {}

  static create__ErrorEventWrappingImplementation() native {
    return new _ErrorEventWrappingImplementation();
  }

  String get filename() { return _get__ErrorEvent_filename(this); }
  static String _get__ErrorEvent_filename(var _this) native;

  int get lineno() { return _get__ErrorEvent_lineno(this); }
  static int _get__ErrorEvent_lineno(var _this) native;

  String get message() { return _get__ErrorEvent_message(this); }
  static String _get__ErrorEvent_message(var _this) native;

  void initErrorEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, String messageArg = null, String filenameArg = null, int linenoArg = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (messageArg === null) {
            if (filenameArg === null) {
              if (linenoArg === null) {
                _initErrorEvent(this);
                return;
              }
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (messageArg === null) {
            if (filenameArg === null) {
              if (linenoArg === null) {
                _initErrorEvent_2(this, typeArg);
                return;
              }
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (messageArg === null) {
            if (filenameArg === null) {
              if (linenoArg === null) {
                _initErrorEvent_3(this, typeArg, canBubbleArg);
                return;
              }
            }
          }
        } else {
          if (messageArg === null) {
            if (filenameArg === null) {
              if (linenoArg === null) {
                _initErrorEvent_4(this, typeArg, canBubbleArg, cancelableArg);
                return;
              }
            }
          } else {
            if (filenameArg === null) {
              if (linenoArg === null) {
                _initErrorEvent_5(this, typeArg, canBubbleArg, cancelableArg, messageArg);
                return;
              }
            } else {
              if (linenoArg === null) {
                _initErrorEvent_6(this, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg);
                return;
              } else {
                _initErrorEvent_7(this, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg, linenoArg);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initErrorEvent(receiver) native;
  static void _initErrorEvent_2(receiver, typeArg) native;
  static void _initErrorEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initErrorEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initErrorEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, messageArg) native;
  static void _initErrorEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg) native;
  static void _initErrorEvent_7(receiver, typeArg, canBubbleArg, cancelableArg, messageArg, filenameArg, linenoArg) native;

  String get typeName() { return "ErrorEvent"; }
}
