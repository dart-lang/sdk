// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests how nullability is inferred for a final field which is implicitly
// initialized to null. This is a regression test for
// https://github.com/flutter/flutter/issues/21957.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

class A {}

class X {
  final A f;
  X.empty() : f = null;
  X.full() : f = A();
}

bool doit(bool choice) {
  X x = choice ? X.full() : X.empty();
  return x.f == null;
}

class Y {
  final A f;
  Y.c0() : f = A();
  Y.c1() : f = null;
  Y.c2() : f = A();
}

bool doit2(int choice) {
  Y y;
  switch (choice) {
    case 0:
      y = new Y.c0();
      break;
    case 1:
      y = new Y.c1();
      break;
    case 2:
      y = new Y.c2();
      break;
  }
  return y.f == null;
}

void main() {
  for (int i = 0; i < 100; i++) {
    bool ping = (i & 1) == 0;
    bool result = doit(ping);
    Expect.equals(result, !ping);

    bool result2 = doit2(i % 3);
    Expect.equals(result2, (i % 3) != 0 && (i % 3) != 2);
  }
}
