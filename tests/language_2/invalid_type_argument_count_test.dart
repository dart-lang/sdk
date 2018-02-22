// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test top level field.
dynamic // Formatter shouldn't join this line.
    <int> //           //# 01: compile-time error
    x1 = 42;

class Foo {
  // Test class member.
  dynamic // Formatter shouldn't join this line.
      <int> //         //# 02: compile-time error
      x2 = 42;

  Foo() {
    print(x2);
  }
}

main() {
  print(x1);

  new Foo();

  // Test local variable.
  dynamic // Formatter shouldn't join this line.
      <int> //         //# 03: compile-time error
      x3 = 42;
  print(x3);

  foo(42);
}

// Test parameter.
void foo(
    dynamic // Formatter shouldn't join this line.
        <int> //       //# 04: compile-time error
        x4) {
  print(x4);
}
