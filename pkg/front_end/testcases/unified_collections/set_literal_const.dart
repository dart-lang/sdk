// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const Set<int>? nullableIntSet1 = <int>{0, 1, 2};
const Set<int>? nullableIntSet2 = null;
const List<int> intList = <int>[3, 4, 5];
const Set<int> intSet = <int>{6, 7, 8};
const Set<num> numSet = <num>{9, 10, 11};
const Set<(int, int)> intIntSet = <(int, int)>{(12, 13), (14, 15)};

const num? nullableNum1 = 16;
const num? nullableNum2 = null;

main() {
  const bool b1 = true;
  const bool b2 = false;
  const <num>{
    17,
    ?nullableNum1,
    ?nullableNum2,
    if (b1) 18,
    if (b2) 19 else 20,
    // TODO(johnniwinther): Support these:
    // if (intList case [var a, ...]) a,
    // if (intList case [_, var b, ...]) b else 21,
    ...intSet,
    ...numSet,
    ...?nullableIntSet1,
    ...?nullableIntSet2,
  };
}
