// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

var inscrutable = (int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

@Native("A")
class A {
}

@Native("B")
class B implements Comparable {
}

@Native("C")
class C implements Pattern {
}

@Native("D")
class D implements Pattern, Comparable {
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


checkTest(value, expectComparable, expectPattern) {
  Expect.equals(expectComparable, value is Comparable);
  Expect.equals(expectPattern, value is Pattern);
}

checkCast(value, expectComparable, expectPattern) {
  if (expectComparable) {
    Expect.identical(value, value as Comparable);
  } else {
    Expect.throws(() => value as Comparable);
  }
  if (expectPattern) {
    Expect.identical(value, value as Pattern);
  } else {
    Expect.throws(() => value as Pattern);
  }
}

checkAll(check) {
  var things =
      [[], 4, 4.2, 'foo', new Object(), makeA(), makeB(), makeC(), makeD()];
  value(i) => things[inscrutable(i)];

  check(value(0), false, false);  // List
  check(value(1), true, false);   // int
  check(value(2), true, false);   // num
  check(value(3), true, true);    // String
  check(value(4), false, false);  // Object
  check(value(5), false, false);  // A
  check(value(6), true, false);   // B
  check(value(7), false, true);   // C
  check(value(8), true, true);    // D
}

main() {
  setup();

  checkAll(checkTest);
  checkAll(checkCast);
}
