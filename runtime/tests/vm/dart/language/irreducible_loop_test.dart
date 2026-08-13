// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

// This method forms an infinite, irreducible loop. As long as we
// don't enter any of the branches, the method terminates. The test
// is included to ensure an irreducible loop does not break anything
// in the compiler.
int bar(int x) {
  switch (x) {
    case_1:
    case 1:
      continue case_2;
    case_2:
    case 2:
      continue case_1;
  }
  return x;
}

main() {
  for (var i = -50; i <= 0; i++) {
    Expect.equals(i, bar(i));
  }
  for (var i = 3; i <= 50; i++) {
    Expect.equals(i, bar(i));
  }
}
