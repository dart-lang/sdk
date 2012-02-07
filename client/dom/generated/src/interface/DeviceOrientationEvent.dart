// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface DeviceOrientationEvent extends Event {

  final bool absolute;

  final num alpha;

  final num beta;

  final num gamma;

  void initDeviceOrientationEvent(String type, bool bubbles, bool cancelable, num alpha, num beta, num gamma, bool absolute);
}
