// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int m;
  A() : m = 1;

  // Named constructor may not conflict with names of methods and fields.
  A.foo() : m = 2;
  int foo(int a, int b) => a + b * m;
}

test() {
  new A().foo();
  new A().foo(1, 2);
  new A.foo();
  new A.foo(1, 2);
}

main() {}
