// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Test that aliasing of thrown exception is handled correctly.
//

import 'package:expect/expect.dart';

class X {
  int v = 0;
}

class Y {
  final x = X();
}

void foo() {
  var y = Y();
  try {
    throw y.x;
  } on X catch (e) {
    e.v = 10; // e is an alias of y.x
  }
  Expect.equals(10, y.x.v); // should be 10 not 0.
}

void bar() {
  var o = X();
  try {
    throw o;
  } on X catch (e) {
    e.v = 10; // e is an alias of o
  }
  Expect.equals(10, o.v);
}

main() {
  foo();
  bar();
}
