// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that hidden native class names are not used by generated code.

class AA native "BB" {
  get name => 'AA';
  static AA create() => makeA();
}

class BB native "C" {
  get name => 'BB';
  static BB create() => makeB();
}

class C {  // Ordinary class with name clashing with native class.
  get name => 'C';
  static C create() => new C();
}

makeA() native;
makeB() native;

void setup1() native """
// Poison hidden native names 'BB' and 'C' to prove the compiler didn't place
// anthing on the hidden native class.
BB = null;
C = null;
""";

void setup2() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function BB(){}
function C(){}
makeA = function(){return new BB};  // AA is "*BB"
makeB = function(){return new C};  // BB is "*C"
""";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  setup1();
  setup2();

  var things = [AA.create(), BB.create(), C.create()];
  var a = things[inscrutable(0)];
  var b = things[inscrutable(1)];
  var c = things[inscrutable(2)];

  Expect.equals('AA', a.name);
  Expect.equals('BB', b.name);
  Expect.equals('C', c.name);
}
