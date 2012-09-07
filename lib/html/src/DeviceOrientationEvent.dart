// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

interface DeviceOrientationEvent extends Event default DeviceOrientationEventWrappingImplementation {

  DeviceOrientationEvent(String type, double alpha, double beta, double gamma,
      [bool canBubble, bool cancelable]);

  num get alpha;

  num get beta;

  num get gamma;
}
