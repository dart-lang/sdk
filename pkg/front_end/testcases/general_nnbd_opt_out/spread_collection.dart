// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

main() {
  final aList = <int>[
    1,
    ...[2],
    ...?[3]
  ];
  final aMap = <int, int>{
    1: 1,
    ...{2: 2},
    ...?{3: 3}
  };
  final aSet = <int>{
    1,
    ...[2],
    ...?[3]
  };
  final aSetOrMap = {...foo()};

  print(aList);
  print(aSet);
  print(aMap);
}

foo() => null;
