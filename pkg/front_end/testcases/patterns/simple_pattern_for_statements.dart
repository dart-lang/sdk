// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) {
  for (var [int i] = x; true;) {
    return i;
  }
}

test2(List<int> x) {
  List<int> result = [];
  for (var [c, n] = x; c < n; result.add(c)) {
    result.add(c);
    c++;
  }
  return result;
}

main() {
  expectEquals(test1([0]), 0);
  expectThrows(() => test1([]));

  expectEquals(
    listToString(test2([1, 2])),
    listToString([1, 2]),
  );
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
    throw "Expected function to throw.";
  }
}

listToString(List list) => "[${list.map((e) => '${e}').join(',')}]";
