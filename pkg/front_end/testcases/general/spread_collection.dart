// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

List<int>? nullableList = [3];
Map<int, int>? nullableMap = {3: 3};

main() {
  final aList = <int>[
    1,
    ...[2],
    ...?nullableList
  ];
  final aMap = <int, int>{
    1: 1,
    ...{2: 2},
    ...?nullableMap
  };
  final aSet = <int>{
    1,
    ...[2],
    ...?nullableList
  };
  final aSetOrMap = {...foo()};

  print(aList);
  print(aSet);
  print(aMap);
}

foo() => null;
