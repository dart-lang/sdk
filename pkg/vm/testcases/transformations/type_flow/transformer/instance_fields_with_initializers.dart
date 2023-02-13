// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for tree shaking of instance fields with initializers.

int sideEffect(int x) {
  print(x);
  return x;
}

class A {
  int f1 = sideEffect(1);
  int f2 = sideEffect(2);
  int f3 = 3;
  static int f4 = sideEffect(40); // Not evaluated in constructor.
  late int f5 = sideEffect(50); // Not evaluated in constructor.
  late final int f6 = sideEffect(60); // Not evaluated in constructor.
  int f7 = sideEffect(7); // Used/retained.
  int f8 = sideEffect(8);

  A(this.f8)
      : f1 = sideEffect(100),
        f2 = sideEffect(200);

  A.foo() : this(800);
  A.bar(this.f1) : f8 = sideEffect(801);
}

main() {
  // Use all constructors.
  A(-8);
  A.foo();
  A.bar(-1);

  // Use f4, f5, f6, f7.
  A obj = A.foo();
  print(A.f4 + obj.f5 + obj.f6 + obj.f7);
}
