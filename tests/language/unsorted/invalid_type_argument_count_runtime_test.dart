// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test top level field.
dynamic // Formatter shouldn't join this line.

    x1 = 42;

class Foo {
  // Test class member.
  dynamic // Formatter shouldn't join this line.

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

      x3 = 42;
  print(x3);

  foo(42);
}

// Test parameter.
void foo(
    dynamic // Formatter shouldn't join this line.

        x4) {
  print(x4);
}
