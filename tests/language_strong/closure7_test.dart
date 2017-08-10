// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that implicitly bound closures work correctly

class A {
  foo() => 499;
  fooo() => 4999; // Implicit closure class can be shared with foo.
  bar(x, {y: 8, z: 10}) => "1 $x $y $z";
  gee(x, {y: 9, z: 11}) => "2 $x $y $z"; // Must not be shared with "bar".
  toto(x, {y: 8, z: 10}) => "3 $x $y $z"; // Could be shared with "bar".

  fisk(x, {y: 8, zz: 10}) => "4 $x $y $zz";
  titi(x, {y: 8, zz: 77}) => "5 $x $y $zz"; // Could be shared with "fisk",
  // because default-val is never used.
}

class B {
  // All implicit closures of B can be shared with their equivalent functions
  // of A.
  foo() => 4990;
  fooo() => 49990;
  bar(x, {y: 8, z: 10}) => "1B $x $y $z";
  gee(x, {y: 9, z: 11}) => "2B $x $y $z";
  toto(x, {y: 8, z: 10}) => "3B $x $y $z";
  fisk(x, {y: 8, zz: 10}) => "4B $x $y $zz";
  titi(x, {y: 8, zz: 77}) => "5B $x $y $zz";
}

tearOffFoo(o) => o.foo;
tearOffFooo(o) => o.fooo;
tearOffBar(o) => o.bar;
tearOffGee(o) => o.gee;
tearOffToto(o) => o.toto;
tearOffFisk(o) => o.fisk;
tearOffTiti(o) => o.titi;

main() {
  var a = new A();
  var b = new B();
  Expect.equals(499, tearOffFoo(a)());
  Expect.equals(4990, tearOffFoo(b)());
  Expect.equals(4999, tearOffFooo(a)());
  Expect.equals(49990, tearOffFooo(b)());

  var barA = tearOffBar(a);
  var barB = tearOffBar(b);
  var geeA = tearOffGee(a);
  var geeB = tearOffGee(b);
  var totoA = tearOffToto(a);
  var totoB = tearOffToto(b);
  Expect.equals("1 33 8 10", barA(33));
  Expect.equals("1B 33 8 10", barB(33));
  Expect.equals("2 33 9 11", geeA(33));
  Expect.equals("2B 33 9 11", geeB(33));
  Expect.equals("3 33 8 10", totoA(33));
  Expect.equals("3B 33 8 10", totoB(33));

  Expect.equals("1 35 8 10", barA(35));
  Expect.equals("1B 35 8 10", barB(35));
  Expect.equals("2 35 9 11", geeA(35));
  Expect.equals("2B 35 9 11", geeB(35));
  Expect.equals("3 35 8 10", totoA(35));
  Expect.equals("3B 35 8 10", totoB(35));

  Expect.equals("1 35 8 77", barA(35, z: 77));
  Expect.equals("1B 35 8 77", barB(35, z: 77));
  Expect.equals("2 35 9 77", geeA(35, z: 77));
  Expect.equals("2B 35 9 77", geeB(35, z: 77));
  Expect.equals("3 35 8 77", totoA(35, z: 77));
  Expect.equals("3B 35 8 77", totoB(35, z: 77));

  Expect.equals("1 35 8 77", barA(35, z: 77));
  Expect.equals("1B 35 8 77", barB(35, z: 77));
  Expect.equals("2 35 9 77", geeA(35, z: 77));
  Expect.equals("2B 35 9 77", geeB(35, z: 77));
  Expect.equals("3 35 8 77", totoA(35, z: 77));
  Expect.equals("3B 35 8 77", totoB(35, z: 77));

  var fiskA = tearOffFisk(a);
  var fiskB = tearOffFisk(b);
  var titiA = tearOffTiti(a);
  var titiB = tearOffTiti(b);

  Expect.equals("4 311 8 987", fiskA(311, zz: 987));
  Expect.equals("4B 311 8 987", fiskB(311, zz: 987));
  Expect.equals("5 311 8 987", titiA(311, zz: 987));
  Expect.equals("5B 311 8 987", titiB(311, zz: 987));

  Expect.equals("4 311 765 987", fiskA(311, y: 765, zz: 987));
  Expect.equals("4B 311 765 987", fiskB(311, y: 765, zz: 987));
  Expect.equals("5 311 765 987", titiA(311, y: 765, zz: 987));
  Expect.equals("5B 311 765 987", titiB(311, y: 765, zz: 987));
}
