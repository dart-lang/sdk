// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

T id<T>(T t) => t;
Set<int>? nullableIntSet1 = {0, 1, 2};
Set<int>? nullableIntSet2 = null;
var intList = [0, 1, 2];
var intSet = {0, 1, 2};
Set<num> numSet = {0, 1, 2};
var intIntSet = {(0, 1), (2, 3)};

num? nullableNum1 = 0;
num? nullableNum2 = null;

main() {
  bool b1 = true;
  bool b2 = false;
  var set = {
    0,
    id(0),
    for (int i = 0; i < intList.length; i++) intList[i],
    for (var (i, j) = (0, 1); i < intList.length; i++) intList[i] + j,
    for (var e in intSet) e,
    for (var e in numSet) e,
    for (var (a, b) in intIntSet) a,
    ?nullableNum1,
    ?nullableNum2,
    if (b1) 4,
    if (b2) 5 else 6,
    if (intList case [var a, ...]) a,
    if (intList case [_, var b, ...]) b else 7,
    ...intSet,
    ...numSet,
    ...?nullableIntSet1,
    ...?nullableIntSet2,
  };
}
