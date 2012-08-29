// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

// When attempting to call a nonexistent constructor, check that a
// NoSuchMethodException is thrown.

foo() {
  throw 'hest';
}

class A {
  A.foo(var x) {}
}

main() {
  int i = 0;
  new A.foo(42);
  try {
    new A.bar(foo());
  } on String catch (e) {
    i = 1;
  }
  Expect.equals(1, i);
  try {
    new A();
  } on NoSuchMethodException catch (e) {
    i = 2;
  }
  Expect.equals(2, i);
}
