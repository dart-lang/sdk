// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that we don't hit unbalanced stack after deoptimization from LoadField
// back to getter call.

// VMOptions=--no-use-osr --optimization-counter-threshold=10 --no-background-compilation

int counter = 0;

class A {
  late final Object field = init();

  @pragma('vm:never-inline')
  int init() {
    counter++;
    if (counter > 20) {
      finalizeB();
    }
    return counter;
  }
}

class B extends A {
  final Object field = "Foo";
}

@pragma('vm:never-inline')
finalizeB() {
  print(new B().field);
}

@pragma('vm:never-inline')
test(A a) {
  print(a.field);
}

main() {
  for (var i = 0; i < 100; i++) {
    test(new A());
  }
}
