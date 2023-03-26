// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x, dynamic another) {
  return {1: 1, if (x case String y) ...another, 3: 3};
}

test2(bool b, dynamic x, dynamic another) {
  return {1: 1, if (b) if (x case String y) ...another, 3: 3};
}

test3(dynamic x, dynamic y, dynamic another) {
  return {1: 1, if (x case int x2) 2: x2 else if (y case int y2) ...another, 3: 3};
}

main() {
  expectEquals(
    mapToString(test1("foo", {2: 2})),
    mapToString({1: 1, 2: 2, 3: 3}),
  );
  expectEquals(
    mapToString(test1(false, {2: 2})),
    mapToString({1: 1, 3: 3}),
  );

  expectEquals(
    mapToString(test2(true, "foo", {2: 2})),
    mapToString({1: 1, 2: 2, 3: 3}),
  );
  expectEquals(
    mapToString(test2(false, "foo", {2: 2})),
    mapToString({1: 1, 3: 3}),
  );
  expectEquals(
    mapToString(test2(true, false, {2: 2})),
    mapToString({1: 1, 3: 3}),
  );

  expectEquals(
    mapToString(test3(0, 1, {2: 2})),
    mapToString({1: 1, 2: 0, 3: 3}),
  );
  expectEquals(
    mapToString(test3("foo", 1, {2: 2})),
    mapToString({1: 1, 2: 2, 3: 3}),
  );
  expectEquals(
    mapToString(test3("foo", "bar", {2, 2})),
    mapToString({1: 1, 3: 3}),
  );
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equals to '${y}'.";
  }
}

mapToString(Map map) {
  List<String> entryStrings = [];
  for (var entry in map.entries) {
    entryStrings.add("${entry.key}:${entry.value}");
  }
  entryStrings.sort();
  return "{${entryStrings.join(',')}}";
}
