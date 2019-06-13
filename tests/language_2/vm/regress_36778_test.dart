// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check for length overflow when eliminating write barriers for variable-length
// objects.
//
// VMOptions=--deterministic --optimization_counter_threshold=5 --optimization_level=3

import "package:expect/expect.dart";

List foo(int a) {
  if (a >= 100) {
    return List.filled(2305843009213693951, 1);
  }
  return null;
}

main() {
  for (int i = 0; i < 100; i++) {
    List x = foo(i);
    Expect.equals(null, x);
  }
}
