// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(dynamic x) => {1: 1, if (x case int y) 2: y, 3: 3};

test2(dynamic x) => {1: 1, if (x case String y) 2: y else 2: null, 3: 3};

test3(dynamic x) => {1: 1, if (x case bool b when b) 2: b, 3: 3};

main() {
  expectEquals(
    mapToString(test1(0)),
    mapToString({1: 1, 2: 0, 3: 3}),
  );
  expectEquals(
    mapToString(test1("foo")),
    mapToString({1: 1, 3: 3}),
  );

  expectEquals(
    mapToString(test2("foo")),
    mapToString({1: 1, 2: "foo", 3: 3}),
  );
  expectEquals(
    mapToString(test2(false)),
    mapToString({1: 1, 2: null, 3: 3}),
  );

  expectEquals(
    mapToString(test3(true)),
    mapToString({1: 1, 2: true, 3: 3}),
  );
  expectEquals(
    mapToString(test3(false)),
    mapToString({1: 1, 3: 3}),
  );
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '${x}' to be equal to '${y}'.";
  }
}

mapToString(Map<dynamic, dynamic> map) {
  List<String> entryStrings = [
    for (var entry in map.entries)
      "${entry.key}:${entry.value}"
  ];
  entryStrings.sort();
  return "{${entryStrings.join(',')}}";
}
