// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import 'dart:math';

main() {
  Duration d, d1;

  d1 = new Duration(microseconds: pow(2, 53));
  d = d1 * 2;
  Expect.equals(pow(2, 54), d.inMicroseconds);
  d = d1 * 1.5;
  Expect.equals(pow(2, 53).toDouble() * 1.5, d.inMicroseconds);
  Expect.isTrue(d.inMicroseconds is int);

  // Test that we lose precision when multiplying with a double.
  d = new Duration(microseconds: pow(2, 53) + 1) * 1.0;
  Expect.equals(0, d.inMicroseconds % 2);
}
