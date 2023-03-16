// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1() {
  for (var [int a2, b2, ...List<int> c2] in [[3, 4, 5, 6]]) {
    return c2.first.isEven;
  }
}

test2() {
  return [
    for (var [int a2, b2, ...List<int> c2] in [[3, 4, 5, 6]])
      c2.first.isEven
  ];
}

Iterable<bool> test3() {
  return {
    for (var [int a2, b2, ...List<int> c2] in [[3, 4, 5, 6]])
      c2.first.isEven
    };
}

test4() {
  return {
    for (var [int a2, b2, ...List<int> c2] in [[3, 4, 5, 6]])
      c2.first: c2.first.isEven
    };
}
