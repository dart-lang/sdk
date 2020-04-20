// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that VM is able to handle certain cases of unreachable code.

// VMOptions=--no_background_compilation --optimization_counter_threshold=10

import "package:expect/expect.dart";

class A {
  dynamic next;
}

test1(A arg1, bool arg2, bool arg3) {
  assert(arg1.next == (arg2 ?? arg3));
}

test2(A arg1, bool arg2, bool arg3) {
  print(((throw 'Error') as dynamic).next == (arg2 ?? arg3));
}

void doTests() {
  test1(new A(), null, null);
  Expect.throws(() {
    test2(new A(), null, null);
  });
}

void main() {
  for (int i = 0; i < 20; i++) {
    doTests();
  }
}
