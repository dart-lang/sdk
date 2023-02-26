// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() => <dynamic, dynamic>{for (var [i] in []) i: i};

test2(dynamic x, dynamic another) => {
  1: 1,
  for (var [i] in x) for (var [j] in x) ...another,
};


main() {
  expectEquals(
    mapToString(test1()),
    mapToString({}),
  );
  expectEquals(
    mapToString(test2([], {2: 2})),
    mapToString({1: 1}),
  );
  expectEquals(
    mapToString(test2([[0], [1], [2]], {2: 2})),
    mapToString({1: 1, 2: 2}),
  );
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}

mapToString(Map map) {
  List<String> entryStrings = [for (var e in map.entries) "${e.key}:${e.value}"];
  entryStrings.sort();
  return "{${entryStrings.join(',')}}";
}
