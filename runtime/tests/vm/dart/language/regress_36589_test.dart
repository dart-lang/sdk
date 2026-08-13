// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Non-smi constant indices for load and store indexed (dartbug.com/36589).
//
// VMOptions=--deterministic --optimization_counter_threshold=5

import "package:expect/expect.dart";

List<int?> mX = new List.filled(1, null);

@pragma('vm:never-inline')
int? foo() {
  return mX[8589934591];
}

@pragma('vm:never-inline')
foo_store() {
  mX[8589934591] = 0;
}

@pragma('vm:never-inline')
int? bar() {
  List<int?> x = new List.filled(1, null);
  return x[8589934591];
}

@pragma('vm:never-inline')
bar_store() {
  List<int?> x = new List.filled(1, null);
  x[8589934591] = 0;
}

main() {
  int i = 0;
  for (int j = 0; j < 10; j++) {
    try {
      i = foo()!;
    } catch (e, s) {
      i++;
    }
  }
  Expect.equals(10, i);
  for (int j = 0; j < 10; j++) {
    try {
      foo_store();
    } catch (e, s) {
      i++;
    }
  }
  Expect.equals(20, i);
  for (int j = 0; j < 10; j++) {
    try {
      i = bar()!;
    } catch (e, s) {
      i++;
    }
  }
  Expect.equals(30, i);
  for (int j = 0; j < 10; j++) {
    try {
      bar_store();
    } catch (e, s) {
      i++;
    }
  }
  Expect.equals(40, i);
}
