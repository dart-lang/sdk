// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Expect the initializer expressions E(i) to be evaluated
// in the order 1, 2, 3, ...
// This test has no inheritance but many fields to flush out issues with
// ordering of fields.

String trace = "";

int E(int i) {
  trace += "$i-";
  return i;
}

class A {
  var j; //      Names are in reverse order to detect sorting by name...
  var i = 0; //  Initialized odd/even to detect these inits affecting order.
  var h;
  var g = 0;
  var f;
  var e = 0;
  var d;
  var c = 0;
  var b;
  var a = 0;

  A()
      : a = E(1), // Initializations in different order to decls.  Ascending...
        b = E(2),
        c = E(3),
        f = E(4), // Descending to be perverse...
        e = E(5),
        d = E(6),
        g = E(7), // Ascending again.
        h = E(8),
        i = E(9),
        j = E(10) {
    Expect.equals(1, a);
    Expect.equals(2, b);
    Expect.equals(3, c);

    Expect.equals(4, f);
    Expect.equals(5, e);
    Expect.equals(6, d);

    Expect.equals(7, g);
    Expect.equals(8, h);
    Expect.equals(9, i);
    Expect.equals(10, j);
  }
}

main() {
  var x = new A();
  Expect.equals('1-2-3-4-5-6-7-8-9-10-', trace);
}
