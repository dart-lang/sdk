// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

check(value, expectComparable, expectPattern) {
  Expect.equals(expectComparable, value is Comparable);
  Expect.equals(expectPattern, value is Pattern);
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

class A native "*A" {
}

class B implements Comparable native "*B" {
}

class C implements Pattern native "*C" {
}

class D implements Pattern, Comparable native "*D" {
}

makeA() native;
makeB() native;
makeC() native;
makeD() native;

void setup() native """
function A() {};
makeA = function() { return new A; }
function B() {};
makeB = function() { return new B; }
function C() {};
makeC = function() { return new C; }
function D() {};
makeD = function() { return new D; }
""";

main() {
  setup();
  var things = [[], 4, 4.2, 'foo', new Object(), makeA(), makeB(),
                makeC(), makeD()];

  check(things[inscrutable(0)], false, false); // List
  check(things[inscrutable(1)], true, false); // int
  check(things[inscrutable(2)], true, false); // num
  check(things[inscrutable(3)], true, true); // string
  check(things[inscrutable(4)], false, false); // Object
  check(things[inscrutable(5)], false, false); // A
  check(things[inscrutable(6)], true, false); // B
  check(things[inscrutable(7)], false, true); // C
  check(things[inscrutable(8)], true, true); // D
}
