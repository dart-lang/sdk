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

  void initDeviceOrientationEvent([String type = null, bool bubbles = null, bool cancelable = null, num alpha = null, num beta = null, num gamma = null]) {
    if (type === null) {
      if (bubbles === null) {
        if (cancelable === null) {
          if (alpha === null) {
            if (beta === null) {
              if (gamma === null) {
                _initDeviceOrientationEvent(this);
                return;
              }
            }
          }
        }
      }
    } else {
      if (bubbles === null) {
        if (cancelable === null) {
          if (alpha === null) {
            if (beta === null) {
              if (gamma === null) {
                _initDeviceOrientationEvent_2(this, type);
                return;
              }
            }
          }
        }
      } else {
        if (cancelable === null) {
          if (alpha === null) {
            if (beta === null) {
              if (gamma === null) {
                _initDeviceOrientationEvent_3(this, type, bubbles);
                return;
              }
            }
          }
        } else {
          if (alpha === null) {
            if (beta === null) {
              if (gamma === null) {
                _initDeviceOrientationEvent_4(this, type, bubbles, cancelable);
                return;
              }
            }
          } else {
            if (beta === null) {
              if (gamma === null) {
                _initDeviceOrientationEvent_5(this, type, bubbles, cancelable, alpha);
                return;
              }
            } else {
              if (gamma === null) {
                _initDeviceOrientationEvent_6(this, type, bubbles, cancelable, alpha, beta);
                return;
              } else {
                _initDeviceOrientationEvent_7(this, type, bubbles, cancelable, alpha, beta, gamma);
                return;
              }
            }
          }
        }
      }
    }
    throw "Incorrect number or type of arguments";
  }
  static void _initDeviceOrientationEvent(receiver) native;
  static void _initDeviceOrientationEvent_2(receiver, type) native;
  static void _initDeviceOrientationEvent_3(receiver, type, bubbles) native;
  static void _initDeviceOrientationEvent_4(receiver, type, bubbles, cancelable) native;
  static void _initDeviceOrientationEvent_5(receiver, type, bubbles, cancelable, alpha) native;
  static void _initDeviceOrientationEvent_6(receiver, type, bubbles, cancelable, alpha, beta) native;
  static void _initDeviceOrientationEvent_7(receiver, type, bubbles, cancelable, alpha, beta, gamma) native;

  String get typeName() { return "DeviceOrientationEvent"; }
}
