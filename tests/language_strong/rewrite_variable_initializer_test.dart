// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Foo {
  var field = 0;
}

bar(x, y) {
  return x * 100 + y;
}

foo(z) {
  var x = 0, y = x;
  if (z > 0) {
    x = 10;
  }
  if (z > 10) {
    y = 20;
  }
  return bar(x, y);
}

baz(z) {
  var f = new Foo()
    ..field = 10
    ..field = z;
  return f;
}

main() {
  Expect.equals(0, foo(0));
  Expect.equals(1000, foo(5));
  Expect.equals(1020, foo(15));

  Expect.equals(20, baz(20).field);
  Expect.equals(30, baz(30).field);
}
