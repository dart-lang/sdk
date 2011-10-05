// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _HashChangeEventWrappingImplementation extends _EventWrappingImplementation implements HashChangeEvent {
  _HashChangeEventWrappingImplementation() : super() {}

  static create__HashChangeEventWrappingImplementation() native {
    return new _HashChangeEventWrappingImplementation();
  }

  String get newURL() { return _get__HashChangeEvent_newURL(this); }
  static String _get__HashChangeEvent_newURL(var _this) native;

  String get oldURL() { return _get__HashChangeEvent_oldURL(this); }
  static String _get__HashChangeEvent_oldURL(var _this) native;

  void initHashChangeEvent(String type = null, bool canBubble = null, bool cancelable = null, String oldURL = null, String newURL = null) {
    if (type === null) {
      if (canBubble === null) {
        if (cancelable === null) {
          if (oldURL === null) {
            if (newURL === null) {
              _initHashChangeEvent(this);
              return;
            }
          }
        }
      }
    } else {
      if (canBubble === null) {
        if (cancelable === null) {
          if (oldURL === null) {
            if (newURL === null) {
              _initHashChangeEvent_2(this, type);
              return;
            }
          }
        }
      } else {
        if (cancelable === null) {
          if (oldURL === null) {
            if (newURL === null) {
              _initHashChangeEvent_3(this, type, canBubble);
              return;
            }
          }
        } else {
          if (oldURL === null) {
            if (newURL === null) {
              _initHashChangeEvent_4(this, type, canBubble, cancelable);
              return;
            }
          } else {
            if (newURL === null) {
              _initHashChangeEvent_5(this, type, canBubble, cancelable, oldURL);
              return;
            } else {
              _initHashChangeEvent_6(this, type, canBubble, cancelable, oldURL, newURL);
              return;
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initHashChangeEvent(receiver) native;
  static void _initHashChangeEvent_2(receiver, type) native;
  static void _initHashChangeEvent_3(receiver, type, canBubble) native;
  static void _initHashChangeEvent_4(receiver, type, canBubble, cancelable) native;
  static void _initHashChangeEvent_5(receiver, type, canBubble, cancelable, oldURL) native;
  static void _initHashChangeEvent_6(receiver, type, canBubble, cancelable, oldURL, newURL) native;

  String get typeName() { return "HashChangeEvent"; }
}
