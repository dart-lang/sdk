// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  int i;
  for (var [i] = x; true;) {
    return i;
  }
}

test2(dynamic x) {
  for (var [int i] = x; i < 3; i++) {
    int i = -1;
    return i;
  }
}

test3(dynamic x) {
  List<int Function()> functions = [];
  for (var [int i] = x; i < 5; i++) {
    functions.add(() => i);
  }
  return functions.map((f) => f()).fold(0, (a, x) => a + x);
}

main() {
  expectEquals(test1([0]), 0);
  expectThrows(() => test1("foo"));

  expectEquals(test2([0]), -1);

  expectEquals(test3([0]), 10);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
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
