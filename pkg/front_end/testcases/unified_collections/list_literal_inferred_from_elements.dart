// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;
List<int>? nullableIntList1 = [0, 1, 2];
List<int>? nullableIntList2 = null;
var intList = [0, 1, 2];
List<num> numList = [0, 1, 2];
var intIntList = [(0, 1), (2, 3)];

num? nullableNum1 = 0;
num? nullableNum2 = null;

main() {
  bool b1 = true;
  bool b2 = false;
  [
    0,
    id(0),
    for (int i = 0; i < intList.length; i++) intList[i],
    for (var (i, j) = (0, 1); i < intList.length; i++) intList[i] + j,
    for (var e in intList) e,
    for (var e in numList) e,
    for (var (a, b) in intIntList) a,
    ?nullableNum1,
    ?nullableNum2,
    if (b1) 4,
    if (b2) 5 else 6,
    if (intList case [var a, ...]) a,
    if (intList case [_, var b, ...]) b else 7,
    ...intList,
    ...numList,
    ...?nullableIntList1,
    ...?nullableIntList2,
  ];
}
