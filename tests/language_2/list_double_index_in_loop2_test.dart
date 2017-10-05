// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for testing arrays.

import "package:expect/expect.dart";

bar() => true;

tata() => 1.5;

// The type propagation in Dart2Js wrongly took the intersection of all incoming
// types in a loop-phi. In this case the back-edge brought type 'number' which,
// combined with 'integer' (i = 0) was narrowed to 'integer'. As a result no
// check was inserted for the list access.
foo(a) {
  var i;
  if (bar()) {
    // t's desired type is conflicting. Once it is used as array receiver. And
    // once as integer. The backward propagation thus can't decide.
    // The forward declaration, however, will assign type num.
    dynamic t = 0 + tata();
    i = t;
    if (!bar()) t[0];
  } else {
    i = 0;
  }
  for (int j = 0; j < 1; j++) {
    // The phi, combining the two 'i's must reach the conclusion that i is of
    // type num and therefore needs a check before accessing the array.
    a[i];
  }
}

main() {
  Expect.throws(() => foo([1, 2]));
}
