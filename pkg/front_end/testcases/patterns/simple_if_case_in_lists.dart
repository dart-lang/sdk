// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) => [1, if (x case [int y, ...]) y, 1];

test2(dynamic x) => [2, if (x case String y) y else null, 2];

test3(dynamic x) => [3, if (x case bool b when b) b, 3];

main() {
  expectEquals(
    listToString(test1([0, 1, 2])),
    listToString([1, 0, 1]),
  );
  expectEquals(
    listToString(test1([])),
    listToString([1, 1]),
  );
  expectEquals(
    listToString(test1([null])),
    listToString([1, 1]),
  );

  expectEquals(
    listToString(test2("foo")),
    listToString([2, "foo", 2]),
  );
  expectEquals(
    listToString(test2(0)),
    listToString([2, null, 2]),
  );

  expectEquals(
    listToString(test3(true)),
    listToString([3, true, 3]),
  );
  expectEquals(
    listToString(test3(false)),
    listToString([3, 3]),
  );
  expectEquals(
    listToString(test3(null)),
    listToString([3, 3]),
  );
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x} (${x.runtimeType})' to be equal to '${y}' (${y.runtimeType}).";
  }
}

listToString(List<dynamic> list) {
  return "[${list.map((e) => e.toString()).join(',')}]";
}
