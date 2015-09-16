// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that the return type of a method is being registered for both
// its bailout and optimized version in dart2js.

var a;

bar() {
  if (a[0] == 0) {
    // Force bailout version.
    bar();
    // Avoid inlining.
    throw 0;
  }
  for (int i = 0; i < 10; i++) {
    a[0] = 42;
  }
  // This return should say that bar can return an array or unknown.
  return a;
}

foo() {
  if (a[0] == 0) {
    // Avoid inlining.
    throw 0;
  }
  var b = bar();
  // This check used to fail because dart2js was assuming [b] was an
  // array.
  Expect.equals(1, b.length);
}

main() {
  a = new Map();
  bar();
  foo();
}
