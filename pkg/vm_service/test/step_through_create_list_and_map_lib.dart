// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'common/test_helper.dart';

void code() {
  final myList = // LINE_A
      <int>[
    1234567890,
    1234567891,
    1234567892,
    1234567893,
    1234567894,
  ];
  final myConstList = const <int>[
    1234567890,
    1234567891,
    1234567892,
    1234567893,
    1234567894,
  ];
  final myMap = <int, int>{
    1: 42,
    2: 43,
    33242344: 432432432,
    443243232: 543242454,
  };
  final myConstMap = const <int, int>{
    1: 42,
    2: 43,
    33242344: 432432432,
    443243232: 543242454,
  };
  print(myList);
  print(myConstList);
  final lookup = myMap[1]!;
  print(lookup);
  print(myMap);
  print(myConstMap);
  print(myMap[2]);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: code);
}
