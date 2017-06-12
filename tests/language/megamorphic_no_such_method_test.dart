// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test program for correct optimizations related to types fo allocated lists.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Classes to induce polymorphism of degree 10.
class A0 {
  test() => 0;
}

class A1 {
  test() => 1;
}

class A2 {
  test() => 2;
}

class A3 {
  test() => 3;
}

class A4 {
  test() => 4;
}

class A5 {
  test() => 5;
}

class A6 {
  test() => 6;
}

class A7 {
  test() => 7;
}

class A8 {
  test() => 8;
}

class A9 {
  test() => 9;
}

// Class with no test method.
class B {}

test(obj) {
  return obj.test();
}

main() {
  // Trigger optimization of 'test' function.
  List list = [
    new A0(),
    new A1(),
    new A2(),
    new A3(),
    new A4(),
    new A5(),
    new A6(),
    new A7(),
    new A8(),
    new A9()
  ];
  for (int i = 0; i < 20; i++) {
    for (var obj in list) {
      test(obj);
    }
  }
  Expect.throws(() => test(new B()), (e) => e is NoSuchMethodError);
}
