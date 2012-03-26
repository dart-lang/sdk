// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class DeviceOrientationEventWrappingImplementation extends EventWrappingImplementation implements DeviceOrientationEvent {
  DeviceOrientationEventWrappingImplementation._wrap(ptr) : super._wrap(ptr);

  factory DeviceOrientationEventWrappingImplementation(String type,
      double alpha, double beta, double gamma, [bool canBubble = true,
      bool cancelable = true]) {
    final e = dom.document.createEvent("DeviceOrientationEvent");
    e.initDeviceOrientationEvent(
        type, canBubble, cancelable, alpha, beta, gamma);
    return LevelDom.wrapDeviceOrientationEvent(e);
  }

  num get alpha() => _ptr.alpha;

  num get beta() => _ptr.beta;

  num get gamma() => _ptr.gamma;
}
