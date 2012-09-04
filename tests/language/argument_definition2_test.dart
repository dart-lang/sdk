// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

test1(bool passed, [a = 42]) {
  if (passed) {
    Expect.equals(54, a);
    Expect.isTrue(?a);
  } else {
    Expect.equals(42, a);
    Expect.isFalse(?a);
  }
  Expect.isTrue(?passed);
}

test2() {
  var closure = (passed, [a = 42]) {
    if (passed) {
      Expect.equals(54, a);
      Expect.isTrue(?a);
    } else {
      Expect.equals(42, a);
      Expect.isFalse(?a);
    }
    Expect.isTrue(?passed);
  };
  closure(true, 54);
  closure(false);
}

class A {
  test3(bool passed, [a = 42]) {
    if (passed) {
      Expect.equals(54, a);
      Expect.isTrue(?a);
    } else {
      Expect.equals(42, a);
      Expect.isFalse(?a);
    }
    Expect.isTrue(?passed);
  }
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  test1(true, 54);
  test1(false);
  test2();
  new A().test3(true, 54);
  new A().test3(false);

  var things = [test1, test2, new A().test3];

  var closure = things[inscrutable(0)];
  closure(true, 54);
  closure(false);

  closure = things[inscrutable(1)];
  closure();

  closure = things[inscrutable(2)];
  closure(true, 54);
  closure(false);
}
