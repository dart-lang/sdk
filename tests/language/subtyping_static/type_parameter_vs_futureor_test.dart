// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';

typedef LX = X Function<X, Y extends X>(X);
typedef LY = Y Function<X, Y extends X>(X);
typedef LFX = FutureOr<X> Function<X, Y extends X>(X);
typedef LFY = FutureOr<Y> Function<X, Y extends X>(X);

typedef RX = X Function<X, Y extends X>(Y);
typedef RY = Y Function<X, Y extends X>(Y);
typedef RFX = FutureOr<X> Function<X, Y extends X>(Y);
typedef RFY = FutureOr<Y> Function<X, Y extends X>(Y);

void main() {
  Expect.subtype<LX, RX>();
  Expect.notSubtype<LX, RY>();
  Expect.subtype<LX, RFX>();
  Expect.notSubtype<LX, RFY>();
  Expect.subtype<LY, RX>();
  Expect.subtype<LY, RY>();
  Expect.subtype<LY, RFX>();
  Expect.subtype<LY, RFY>();
  Expect.notSubtype<LFX, RX>();
  Expect.notSubtype<LFX, RY>();
  Expect.subtype<LFX, RFX>();
  Expect.notSubtype<LFX, RFY>();
  Expect.notSubtype<LFY, RX>();
  Expect.notSubtype<LFY, RY>();
  Expect.subtype<LFY, RFX>();
  Expect.subtype<LFY, RFY>();
}
