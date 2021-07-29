// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A.new();
}

class B {
  B();
}

class C {
  C();
  C.new(); // Error.
}

class D {
  D.new();
  D(); // Error.
}

class E1 {
  E1._();
  E1();
  factory E1.new() => E1._(); // Error.
}

class E2 {
  E2._();
  factory E2.new() => E2._(); // Error.
  E2();
}

class E3 {
  E3._();
  E3();
  factory E3.new() = E3._; // Error.
}

class E4 {
  E4._();
  factory E4.new() = E4._;
  E4(); // Error.
}

main() {}
