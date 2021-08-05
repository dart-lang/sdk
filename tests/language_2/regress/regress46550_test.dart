// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.9

// VMOptions=--optimization_counter_threshold=100 --deterministic

import "package:expect/expect.dart";

typedef void test1<T extends num>();

void t1<T extends int>() {
  Expect.equals(int, T);
}

const test1 res1 = t1;

main() {
  for (int i = 0; i < 120; ++i) {
    res1();
  }
}
