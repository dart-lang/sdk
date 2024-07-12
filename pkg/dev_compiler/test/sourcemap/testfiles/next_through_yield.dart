// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*Debugger:stepOver*/
void main() {
  for (var i in naturalsTo(2)) {
    /*s:3*/ print(i);
  }
  /*s:4*/
}

Iterable<int> naturalsTo(int n) sync* {
  /*bl*/
  /*sl:1*/ var k = 0;
  while (k < n) {
    yield /*bc:2*/ foo(++k);
  }
}

int foo(int n) {
  return n;
}
