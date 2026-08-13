// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing arrays.

import "package:expect/expect.dart";

bar() => true;

// The type propagation in Dart2Js wrongly took the intersection of all incoming
// types in a loop-phi. In this case the back-edge brought type 'number' which,
// combined with 'integer' (i = 0) was narrowed to 'integer'. As a result no
// check was inserted for the list access.
foo(a) {
  num i = 0;
  while (true) {
    if (i > 1) return a[i];
    if (bar()) {
      // Adding a double guarantees a double result. Therefore guard by an if.
      i = i + 1.5;
    }
  }
}

main() {
  Expect.throws(() => foo([1, 2]));
}
