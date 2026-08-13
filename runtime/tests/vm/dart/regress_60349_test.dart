// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=100 --deterministic

// Verify that constant propagation doesn't perform an incorrect
// optimization involving unwrapped phi.
// Regression test for https://github.com/dart-lang/sdk/issues/60349

import "package:expect/expect.dart";

@pragma('vm:never-inline')
void foo(int? x, int y) {
  List<int> l = [1];
  int ll = l.length; // ll = 1
  int n = 0;
  int? a;
  while (true) {
    int b = 0;
    // As ll == 1, the loop below only ever has one iteration.
    for (int i = 0; i < ll; i++) {
      // y == 2, and n only reaches 1 in this program, but removing this
      // condition makes the bug go away:
      if (n == y) {
        return;
      }
      b = 1234 + n * 1111;
    }

    // On the first iteration, "a" is set to "b" (2025).
    if (n == 0) {
      a = b;
    }

    // This condition is false on the first iteration (1234 vs 2025) and true
    // on the second (2345 vs 2025):
    if (b >= x!) {
      // This should never be true.
      if (b == a) {
        Expect.fail("BUG! $b == $a?!?");
      }
      return;
    }

    n++;
  }
}

void main() {
  for (int i = 0; i < 150; ++i) {
    foo(int.parse('2025'), int.parse('2'));
  }
}
