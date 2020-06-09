// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

int convert(dynamic d) {
  return d.toInt();
}

main() {
  double x = -100.0;
  int count = 0;
  while (x < 100.0) {
    count = count + convert(x);
    x = x + 0.5;
  }
  Expect.equals(-100, count);
  count = convert(42);
  Expect.equals(42, count);
}
