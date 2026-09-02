// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const List<int>? nullableIntList1 = <int>[0, 1, 2];
const List<int>? nullableIntList2 = null;
const List<int> intList = <int>[0, 1, 2];
const List<num> numList = <num>[0, 1, 2];
const List<(int, int)> intIntList = <(int, int)>[(0, 1), (2, 3)];

const num? nullableNum1 = 0;
const num? nullableNum2 = null;

main() {
  const bool b1 = true;
  const bool b2 = false;
  const <num>[
    0,
    ?nullableNum1,
    ?nullableNum2,
    if (b1) 4,
    if (b2) 5 else 6,
    // TODO(johnniwinther): Support these:
    // if (intList case [var a, ...]) a,
    // if (intList case [_, var b, ...]) b else 7,
    ...intList,
    ...numList,
    ...?nullableIntList1,
    ...?nullableIntList2,
  ];
}
