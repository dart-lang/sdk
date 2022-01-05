// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/48043.
// Verifies that loads which may call initializer are not forwarded to
// a previously stored value if it could be an uninitialized sentinel.

// VMOptions=--deterministic --optimization_counter_threshold=120

import "package:expect/expect.dart";

class LateField1 {
  late int n;

  LateField1() {
    print(n);
  }
}

class LateField2 {
  late int n;

  LateField2() {
    print(n);
    n = 31999;
  }
}

class LateField3 {
  late int n;

  LateField3() {
    print(n);
    n = DateTime.now().millisecondsSinceEpoch;
  }
}

void doTests() {
  Expect.throws(() {
    LateField1();
  });
  Expect.throws(() {
    LateField2();
  });
  Expect.throws(() {
    final obj = LateField3();
    print(obj.n);
  });
}

void main() {
  for (int i = 0; i < 150; ++i) {
    doTests();
  }
}
