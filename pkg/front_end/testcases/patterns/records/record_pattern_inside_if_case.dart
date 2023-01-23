// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(Record x) {
  if (x case (1, 2)) {}
  if (x case (1, a: 2)) {}
  if (x case (a: 1, 2)) {}
  if (x case (a: 1, b: 2)) {}
  if (x case (int _, double y, foo: String _!, bar: var _)) {
    return 0;
  } else {
    return 1;
  }

}

test2((int, int) x) {
  if (x case (1, 2)) {}
}

test3((int, {int a}) x) {
  if (x case (1, a: 2)) {}
  if (x case (a: 1, 2)) {}
}

test4(({int a, int b}) x) {
  if (x case (a: 1, b: 2)) {}
}

test5((int, double, {String foo, dynamic bar}) x) {
  if (x case (int _, double y, foo: String _!, bar: var _)) {
    return 0;
  } else {
    return 1;
  }

}
