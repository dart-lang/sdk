// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  Duration d, d1;

  d1 = new Duration(milliseconds: 1);
  d = d1 * 0.005;
  Expect.equals(1000 * 0.005, d.inMicroseconds);
  d = d1 * 0.0;
  Expect.equals(0, d.inMicroseconds);
  d = d1 * -0.005;
  Expect.equals(1000 * -0.005, d.inMicroseconds);
  d = d1 * 0.0015;
  Expect.equals((1000 * 0.0015).round(), d.inMicroseconds);
}
