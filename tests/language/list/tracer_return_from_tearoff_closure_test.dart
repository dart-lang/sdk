// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js's list tracer, that used to not see a
// returned value of a method can escape to places where that method
// is closurized and invoked.

var a = [42];

foo() {
  return a;
}

main() {
  (foo)().clear();
  if (a.length == 1) {
    throw 'Test failed';
  }
}
