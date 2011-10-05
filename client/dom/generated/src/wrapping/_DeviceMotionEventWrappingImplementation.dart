// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DeviceMotionEventWrappingImplementation extends _EventWrappingImplementation implements DeviceMotionEvent {
  _DeviceMotionEventWrappingImplementation() : super() {}

  static create__DeviceMotionEventWrappingImplementation() native {
    return new _DeviceMotionEventWrappingImplementation();
  }

  num get interval() { return _get__DeviceMotionEvent_interval(this); }
  static num _get__DeviceMotionEvent_interval(var _this) native;

  void initDeviceMotionEvent([String type = null, bool bubbles = null, bool cancelable = null]) {
    if (type === null) {
      if (bubbles === null) {
        if (cancelable === null) {
          _initDeviceMotionEvent(this);
          return;
        }
      }
    } else {
      if (bubbles === null) {
        if (cancelable === null) {
          _initDeviceMotionEvent_2(this, type);
          return;
        }
      } else {
        if (cancelable === null) {
          _initDeviceMotionEvent_3(this, type, bubbles);
          return;
        } else {
          _initDeviceMotionEvent_4(this, type, bubbles, cancelable);
          return;
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initDeviceMotionEvent(receiver) native;
  static void _initDeviceMotionEvent_2(receiver, type) native;
  static void _initDeviceMotionEvent_3(receiver, type, bubbles) native;
  static void _initDeviceMotionEvent_4(receiver, type, bubbles, cancelable) native;

  String get typeName() { return "DeviceMotionEvent"; }
}
