// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) => [for (var [int i, int n] = x; i < n; i++) i];

test2(dynamic x) => {
  -1: -1,
  for (var [int i, int n] = x; i < n; i++) i : i,
  -2: -2,
};

test3(dynamic x, dynamic another) => {
  -1: -1,
  for (var [int i1, n1, ...] = x; i1 < n1; i1++)
    for (var [_, _, int i2, n2, ...] = x; i2 < n2; i2++)
      ...another,
  -2: -2,
};

main() {
  expectEquals(
    listToString(test1([0, 3])),
    listToString([0, 1, 2]),
  );
  expectEquals(
    listToString(test1([0, 0])),
    listToString([]),
  );
  expectThrows(() => test1({}));

  expectEquals(
    mapToString(test2([0, 3])),
    mapToString({-2: -2, -1: -1, 0: 0, 1: 1, 2: 2}),
  );
  expectEquals(
    mapToString(test2([0, 0])),
    mapToString({-2: -2, -1: -1}),
  );
  expectThrows(() => test1([]));

  expectEquals(
    mapToString(test3([0, 0, 0, 0], {0: 0})),
    mapToString({-1: -1, -2: -2}),
  );
  expectEquals(
    mapToString(test3([0, 1, 0, 1], {0: 0})),
    mapToString({-1: -1, -2: -2, 0: 0}),
  );
  expectThrows(() => test3([], {}));
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}

listToString(List list) => "[${list.map((e) => '${e}').join(',')}]";

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

mapToString(Map map) {
  List<String> entryStrings = [
    for (var entry in map.entries)
      "${entry.key}:${entry.value}"
  ];
  entryStrings.sort();
  return "[${entryStrings.join(',')}]";
}
