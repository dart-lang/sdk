// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

/*Debugger:stepOver*/

void main() {
  for (var i in naturalsTo(2)) {
    print(i);
  }
}

Iterable<int> naturalsTo(int n) sync* {
  /*bl*/
  /*sl:1*/ var k = 0;
  /*sl:2*/ /*sl:4*/ /*sl:6*/ while (k < n) {
    yield /*bc:3*/ /*bc:5*/ foo(++k);
  }
}

int foo(int n) {
  return n;
}
