// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  switch (x) {
    case int y:
      continue ret0;
    r0:
    ret0:
    case "foo":
    return0:
    case "foobar":
      return 0;
    case double y:
      continue r0;
    case String y:
      continue return0;
    default:
      return 1;
  }
}

test2(dynamic x) {
  switch (x) {
    case String y:
      return "String";
    case int y:
      continue numLabel;
    numLabel:
    case double y:
      return "num";
    case bool y1:
      continue otherLabel;
    case List y2:
    otherLabel:
    default:
      return "other";
  }
}

main() {
  expectEquals(test1(0), 0);
  expectEquals(test1(1), 0);
  expectEquals(test1(2), 0);
  expectEquals(test1("foo"), 0);
  expectEquals(test1("bar"), 0);
  expectEquals(test1("foobar"), 0);
  expectEquals(test1(3.14), 0);
  expectEquals(test1(null), 1);
  expectEquals(test1(false), 1);

  expectEquals(test2("foo"), "String");
  expectEquals(test2(0), "num");
  expectEquals(test2(3.14), "num");
  expectEquals(test2(false), "other");
  expectEquals(test2([1, "2"]), "other");
  expectEquals(test2(null), "other");
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
