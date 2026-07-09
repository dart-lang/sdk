// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dynamic accesses to record fields that have the same name as a getter on some
// other type. Fields used as getters and method calls.  System List type on
// dart2js an 'intercepted', with a different calling convention.

@pragma('dart2js:never-inline')
@pragma('m:never-inline')
int combineFirstLast(dynamic d) {
  return d.first * 10 + d.last;
}

@pragma('dart2js:never-inline')
@pragma('m:never-inline')
int chainFirstLast(dynamic d, int x) {
  return d.last(d.first(x));
}

int mul10(int x) => x * 10;
int add1(int x) => x + 1;

void main() {
  Expect.equals(19, combineFirstLast((first: 1, last: 9)));
  Expect.equals(19, combineFirstLast((last: 9, next: 666, first: 1)));
  Expect.equals(19, combineFirstLast((4, 5, last: 9, first: 1)));
  Expect.equals(19, combineFirstLast([1, 9]));
  Expect.equals(19, combineFirstLast({1, 9}));

  Expect.equals(82, combineFirstLast((first: 8, last: 2)));
  Expect.equals(82, combineFirstLast((last: 2, next: 666, first: 8)));
  Expect.equals(82, combineFirstLast((4, last: 2, first: 8, 5)));
  Expect.equals(82, combineFirstLast([8, 2]));
  Expect.equals(82, combineFirstLast({8, 2}));

  Expect.equals(70, chainFirstLast((first: add1, last: mul10), 6));
  Expect.equals(70, chainFirstLast((first: add1, next: null, last: mul10), 6));
  Expect.equals(70, chainFirstLast((null, last: mul10, null, first: add1), 6));
  Expect.equals(70, chainFirstLast([add1, mul10], 6));
  Expect.equals(70, chainFirstLast({add1, mul10}, 6));

  Expect.equals(61, chainFirstLast((first: mul10, last: add1), 6));
  Expect.equals(61, chainFirstLast([mul10, add1], 6));
  Expect.equals(61, chainFirstLast({mul10, add1}, 6));
}
