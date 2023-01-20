// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  int a;
  [a] = x;
  return a;
}

test2(dynamic x) {
  int a, b, c;
  [c, ...] = [a && b, ...] = x;
  return a + b + c;
}

main() {
  expectEquals(test1([1]), 1);
  expectThrows(() => test1([]));
  expectThrows(() => test1([1, 2, 3]));
  expectThrows(() => test1("foo"));
  expectThrows(() => test1(null));

  expectEquals(test2([1]), 3);
  expectThrows(() => test2(1));
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
  } catch (e) {}
  if (!hasThrown) {
    throw "Expected the function to throw.";
  }
}
