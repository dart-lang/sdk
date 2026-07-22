// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;
Map<int, String>? nullableIntMap1 = <int, String>{0: '0', 1: '1', 2: '2'};
Map<int, String>? nullableIntMap2 = null;
List<int> intList = <int>[0, 1, 2];
Map<int, String> intMap = <int, String>{0: '0', 1: '1', 2: '2'};
Map<num, String> numMap = <num, String>{0: '0', 1: '1', 2: '2'};
List<(int, int)> intIntList = <(int, int)>[(0, 1), (2, 3)];

num? nullableNum1 = 0;
num? nullableNum2 = null;
String? nullableString1 = '0';
String? nullableString2 = null;

main() {
  bool b1 = true;
  bool b2 = false;
  <num, String>{
    0: '0',
    id(0): '0',
    1: id('0'),
    for (int i = 0; i < intList.length; i++) intList[i]: '${intList[i]}',
    for (var (i, j) = (0, 1); i < intList.length; i++) intList[i]: '$j',
    for (var e in intMap.entries) e.key: e.value,
    for (var e in numMap.entries) e.key: e.value,
    for (var (a, b) in intIntList) a: '$b',
    ?nullableNum1: '0',
    ?nullableNum2: '0',
    2: ?nullableString1,
    3: ?nullableString2,
    ?nullableNum1: ?nullableString2,
    ?nullableNum2: ?nullableString1,
    if (b1) 4: '4',
    if (b2) 5: '5' else 6: '6',
    if (intList case [var a, ...]) a: '$a',
    if (intList case [_, var b, ...]) b: '$b' else 7: '7',
    ...intMap,
    ...numMap,
    ...?nullableIntMap1,
    ...?nullableIntMap2,
  };
}
