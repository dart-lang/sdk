// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  const A();
}

mixin B {
  static const int value = 1;
}

class C1 extends A with B {
  const C1();
}

class C2 = A with B;

class C3 extends C2 {
  const C3();
}

mixin D {
  int value = 1;
}

class E1 extends A with D {
  const E1();
}

class E2 = A with D;

class E3 extends E2 {
  const E3();
}

main() {}
