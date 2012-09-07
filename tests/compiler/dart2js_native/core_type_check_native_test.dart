// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

check(value, expectComparable, expectHashable, expectPattern) {
  Expect.equals(expectComparable, value is Comparable);
  Expect.equals(expectHashable, value is Hashable);
  Expect.equals(expectPattern, value is Pattern);
}

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

class A implements Comparable native "*A" {
}

class B implements Hashable native "*B" {
}

class C implements Comparable, Hashable native "*C" {
}

class D implements Pattern native "*D" {
}

class E implements Pattern, Comparable native "*E" {
}

class F implements Pattern, Hashable native "*F" {
}

class G implements Pattern, Hashable, Comparable native "*G" {
}

makeA() native;
makeB() native;
makeC() native;
makeD() native;
makeE() native;
makeF() native;
makeG() native;

void setup() native """ 
function A() {}; 
makeA = function() { return new A; }
function B() {}; 
makeB = function() { return new B; }
function C() {}; 
makeC = function() { return new C; }
function D() {}; 
makeD = function() { return new D; }
function E() {}; 
makeE = function() { return new E; }
function F() {}; 
makeF = function() { return new F; }
function G() {}; 
makeG = function() { return new G; }
""";

main() {
  setup();
  var things = [[], 4, 4.2, 'foo', new Object(), makeA(), makeB(),
                makeC(), makeD(), makeE(), makeF(), makeG()];

  check(things[inscrutable(0)], false, false, false); // List
  check(things[inscrutable(1)], true, true, false); // int
  check(things[inscrutable(2)], true, true, false); // num
  check(things[inscrutable(3)], true, true, true); // string
  check(things[inscrutable(4)], false, false, false); // Object
  check(things[inscrutable(5)], true, false, false); // A
  check(things[inscrutable(6)], false, true, false); // B
  check(things[inscrutable(7)], true, true, false); // C
  check(things[inscrutable(8)], false, false, true); // D
  check(things[inscrutable(9)], true, false, true); // E
  check(things[inscrutable(10)], false, true, true); // F
  check(things[inscrutable(11)], true, true, true); // G
}
