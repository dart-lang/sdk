// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that if, while etc create an implicit scope if the body
// is not a compound statement.

import "package:expect/expect.dart";

class ImplicitScopeTest {
  static bool alwaysTrue() {
    return 1 + 1 == 2;
  }

  static testMain() {
    var a = "foo";
    var b;
    if (alwaysTrue())
      var a = "bar";
    else
      var b = a;
    Expect.equals("foo", a);
    Expect.equals(null, b);

    while (!alwaysTrue()) var a = "bar", b = "baz";
    Expect.equals("foo", a);
    Expect.equals(null, b);

    for (int i = 0; i < 10; i++) var a = "bar", b = "baz";
    Expect.equals("foo", a);
    Expect.equals(null, b);

    do var a = "bar", b = "baz"; while ("black" == "white");
    Expect.equals("foo", a);
    Expect.equals(null, b);
  }
}

main() {
  ImplicitScopeTest.testMain();
}
