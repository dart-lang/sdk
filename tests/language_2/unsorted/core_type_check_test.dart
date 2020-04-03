// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

check(value, expectComparable, expectPattern) {
  Expect.equals(expectComparable, value is Comparable);
  Expect.equals(expectPattern, value is Pattern);
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

class A implements Comparable {
  int compareTo(o) => 0;
}

class B {}

class C implements Pattern {
  matchAsPrefix(String s, [int start = 0]) => null;
  allMatches(String s, [int start = 0]) => null;
}

class D implements Pattern, Comparable {
  int compareTo(o) => 0;
  matchAsPrefix(String s, [int start = 0]) => null;
  allMatches(String s, [int start = 0]) => null;
}

main() {
  var things = [
    [],
    4,
    4.2,
    'foo',
    new Object(),
    new A(),
    new B(),
    new C(),
    new D()
  ];

  check(things[inscrutable(0)], false, false); // List
  check(things[inscrutable(1)], true, false); // int
  check(things[inscrutable(2)], true, false); // num
  check(things[inscrutable(3)], true, true); // string
  check(things[inscrutable(4)], false, false); // Object
  check(things[inscrutable(5)], true, false); // A
  check(things[inscrutable(6)], false, false); // B
  check(things[inscrutable(7)], false, true); // C
  check(things[inscrutable(8)], true, true); // D
}
