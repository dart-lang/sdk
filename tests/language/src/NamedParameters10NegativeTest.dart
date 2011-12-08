// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing named parameters.

// This test is very similar to NamedParameters3NegativeTest, but exersizes a
// different corner case in the frog compiler. frog wasn't detecting unused
// named arguments when no other arguments were expected. So, this test
// purposely passes the exact number of positional parameters 

int test(int a) {
  return a;
}

main() {
  try {
    test(10, x:99);  // 1 positional arg, as expected. Param x does not exist.
  } catch (var e) {
    // This is a negative test that should not compile.
    // If it runs due to a bug, catch and ignore exceptions.
  }
}
