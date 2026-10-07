// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import 'dart:typed_data';

import 'package:expect/expect.dart';

void testZero() {
  final z = Int32x4.zero();
  Expect.equals(0, z.x);
  Expect.equals(0, z.y);
  Expect.equals(0, z.z);
  Expect.equals(0, z.w);
  Expect.equals(0, z.signMask);
}

void main() {
  for (int i = 0; i < 20; i++) testZero();
}
