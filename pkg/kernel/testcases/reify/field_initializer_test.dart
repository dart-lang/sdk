// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library field_initializer_test;

import 'test_base.dart';

p(x) {
  write(x);
  return x;
}

class A<T> {
  var a1 = p("a1");
  var a2;

  A() : a2 = p("a2") {
    p("A");
  }
}

class B<T> extends A<T> {
  var b1 = p("b1");
  var b2 = p("b2");
  var b3;
  var b4;

  B()
      : b3 = p("b3"),
        b4 = p("b4"),
        super() {
    p("B");
  }
}

main() {
  var b = new B();
  expectOutput("b1\nb2\nb3\nb4\na1\na2\nA\nB");
}
