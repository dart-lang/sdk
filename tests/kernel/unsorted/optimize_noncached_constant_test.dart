// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--optimization_counter_threshold=5 --no-background-compilation

void foo(int i) {
  try {
    print(42 ~/ 0 + i);
  } catch (e) {
    return;
  }
  throw "Should have gotten an exception";
}

main() {
  for (int i = 0; i < 10; ++i) {
    foo(i);
  }
}
