// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=10 --no-background-compilation --shared-slow-path-triggers-gc --stacktrace_filter=filter_me

// This tests the stackmaps and environments for safepoints corresponding to
// slow-path stack overflow checks which uses shared runtime stubs.

import 'package:expect/expect.dart';
import 'dart:math';

filter_me() {
  int s = 0;
  for (int i = 0; i < 100; ++i) {
    if (i % 2 == 0) {
      s += i;
    } else {
      s -= i;
    }
  }
  Expect.equals(s, -50);
  double x = 0.0;
  for (int i = 0; i < 100; ++i) {
    if (i % 2 == 0) {
      x = x / 3;
    } else {
      x = x * 2 + 1;
    }
  }
  Expect.isTrue(x - 0.00001 < 3 && x + 0.00001 > 3);
}

main() {
  filter_me();
}
