// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DeviceOrientationEventWrappingImplementation extends _EventWrappingImplementation implements DeviceOrientationEvent {
  _DeviceOrientationEventWrappingImplementation() : super() {}

  static create__DeviceOrientationEventWrappingImplementation() native {
    return new _DeviceOrientationEventWrappingImplementation();
  }

  num get alpha() { return _get__DeviceOrientationEvent_alpha(this); }
  static num _get__DeviceOrientationEvent_alpha(var _this) native;

  num get beta() { return _get__DeviceOrientationEvent_beta(this); }
  static num _get__DeviceOrientationEvent_beta(var _this) native;

  num get gamma() { return _get__DeviceOrientationEvent_gamma(this); }
  static num _get__DeviceOrientationEvent_gamma(var _this) native;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma) {
    _initDeviceOrientationEvent(this, type, bubbles, cancelable, alpha, beta, gamma);
    return;
  }
  static void _initDeviceOrientationEvent(receiver, type, bubbles, cancelable, alpha, beta, gamma) native;

  String get typeName() { return "DeviceOrientationEvent"; }
}
