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

  String get typeName() { return "DeviceMotionEvent"; }
}
