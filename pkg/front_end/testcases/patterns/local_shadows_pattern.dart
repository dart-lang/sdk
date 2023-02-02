// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  switch (x) {
    case int x:
    {
      String x = "foo"; // Ok.
      return x;
    }
    default:
      return "bar";
  }
}

test2(dynamic x) {
  switch (x) {
    case [int x, _]:
    case [_, int x]:
      String x = "foo"; // Ok.
      return x;
    default:
      return "bar";
  }
}

test3(dynamic x) {
  if (x case int x) {
    String x = "foo"; // Ok.
    return x;
  } else {
    return "bar";
  }
}

test4(dynamic x) {
  Function f = () => 0;
  // The then-clause isn't a block.
  if (x case int x) String x = () { f = () => 1; return "foo"; }();
  return f();
}

main() {
  expectEquals(test1(0), "foo");
  expectEquals(test1("foo"), "bar");
  expectEquals(test2([0, false]), "foo");
  expectEquals(test2([false, 0]), "foo");
  expectEquals(test2("foo"), "bar");
  expectEquals(test3(0), "foo");
  expectEquals(test3("foo"), "bar");
  expectEquals(test4(0), 1);
  expectEquals(test4("foo"), 0);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}
