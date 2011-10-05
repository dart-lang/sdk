// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DeviceMotionEventWrappingImplementation extends EventWrappingImplementation implements DeviceMotionEvent {
  DeviceMotionEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get interval() { return _ptr.interval; }

  void initDeviceMotionEvent(String type, bool bubbles, bool cancelable) {
    _ptr.initDeviceMotionEvent(type, bubbles, cancelable);
    return;
  }

  String get typeName() { return "DeviceMotionEvent"; }
}
