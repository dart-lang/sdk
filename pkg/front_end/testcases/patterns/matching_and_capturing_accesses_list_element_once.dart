// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

class A with ListMixin<int> {
  int count = 0;
  int operator[](int index) {
    count++;
    return 0;
  }
  void operator[]=(int index, int value) {}
  int get length => 2;
  void set length(int value) {}
}

main() {
  A a = new A();
  if (a case [int x, int y]) {
    expectEquals(x, 0);
    expectEquals(y, 0);
  }
  expectEquals(a.count, 2);
}

expectEquals(x, y) {
  if (x != y) {
    throw "Expected ${x} to be equal to ${y}.";
  }
}
