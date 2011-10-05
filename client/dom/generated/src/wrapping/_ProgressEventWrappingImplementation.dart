// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ProgressEventWrappingImplementation extends _EventWrappingImplementation implements ProgressEvent {
  _ProgressEventWrappingImplementation() : super() {}

  static create__ProgressEventWrappingImplementation() native {
    return new _ProgressEventWrappingImplementation();
  }

  bool get lengthComputable() { return _get__ProgressEvent_lengthComputable(this); }
  static bool _get__ProgressEvent_lengthComputable(var _this) native;

  int get loaded() { return _get__ProgressEvent_loaded(this); }
  static int _get__ProgressEvent_loaded(var _this) native;

  int get total() { return _get__ProgressEvent_total(this); }
  static int _get__ProgressEvent_total(var _this) native;

  void initProgressEvent([String typeArg = null, bool canBubbleArg = null, bool cancelableArg = null, bool lengthComputableArg = null, int loadedArg = null, int totalArg = null]) {
    if (typeArg === null) {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (lengthComputableArg === null) {
            if (loadedArg === null) {
              if (totalArg === null) {
                _initProgressEvent(this);
                return;
              }
            }
          }
        }
      }
    } else {
      if (canBubbleArg === null) {
        if (cancelableArg === null) {
          if (lengthComputableArg === null) {
            if (loadedArg === null) {
              if (totalArg === null) {
                _initProgressEvent_2(this, typeArg);
                return;
              }
            }
          }
        }
      } else {
        if (cancelableArg === null) {
          if (lengthComputableArg === null) {
            if (loadedArg === null) {
              if (totalArg === null) {
                _initProgressEvent_3(this, typeArg, canBubbleArg);
                return;
              }
            }
          }
        } else {
          if (lengthComputableArg === null) {
            if (loadedArg === null) {
              if (totalArg === null) {
                _initProgressEvent_4(this, typeArg, canBubbleArg, cancelableArg);
                return;
              }
            }
          } else {
            if (loadedArg === null) {
              if (totalArg === null) {
                _initProgressEvent_5(this, typeArg, canBubbleArg, cancelableArg, lengthComputableArg);
                return;
              }
            } else {
              if (totalArg === null) {
                _initProgressEvent_6(this, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg);
                return;
              } else {
                _initProgressEvent_7(this, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg, totalArg);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initProgressEvent(receiver) native;
  static void _initProgressEvent_2(receiver, typeArg) native;
  static void _initProgressEvent_3(receiver, typeArg, canBubbleArg) native;
  static void _initProgressEvent_4(receiver, typeArg, canBubbleArg, cancelableArg) native;
  static void _initProgressEvent_5(receiver, typeArg, canBubbleArg, cancelableArg, lengthComputableArg) native;
  static void _initProgressEvent_6(receiver, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg) native;
  static void _initProgressEvent_7(receiver, typeArg, canBubbleArg, cancelableArg, lengthComputableArg, loadedArg, totalArg) native;

  String get typeName() { return "ProgressEvent"; }
}
