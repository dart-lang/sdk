// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  var [int y] = x;
  return y;
}

test2(dynamic x) {
  var [String a, ..., String b] = x;
  return a + b;
}

main() {
  expectEquals(test1([0]), 0);
  expectThrows(() => test1([]));
  expectThrows(() => test1([0, 1, 2]));
  expectEquals(test2(["one", "two", "three", "four"]), "onefour");
  expectThrows(() => test2(["one"]));
  expectThrows(() => test2("one"));
  expectThrows(() => test2(null));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}

expectThrows(void Function() f) {
  bool hasThrown = true;
  try {
    f();
    hasThrown = false;
  } catch(e) {}
  if (!hasThrown) {
    throw "Expected function to throw.";
  }
}
