// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

// VMOptions=--optimization_counter_threshold=5 --no-background_compilation

import "package:expect/expect.dart";

main() {
  for (var i = 0; i < 10; i++) {
    Expect.equals(0x40000000, (i - i) - -1073741824);
    Expect.equals(0x4000000000000000, (i - i) - -4611686018427387904);
  }
}
