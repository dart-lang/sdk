// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class DeviceOrientationEventWrappingImplementation extends EventWrappingImplementation implements DeviceOrientationEvent {
  DeviceOrientationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get alpha() { return _ptr.alpha; }

  num get beta() { return _ptr.beta; }

  num get gamma() { return _ptr.gamma; }

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma) {
    _ptr.initDeviceOrientationEvent(type, bubbles, cancelable, alpha, beta, gamma);
    return;
  }

  String get typeName() { return "DeviceOrientationEvent"; }
}
