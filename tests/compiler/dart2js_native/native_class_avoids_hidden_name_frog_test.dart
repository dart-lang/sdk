// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_js_helper";
import "package:expect/expect.dart";

// Test that hidden native class names are not used by generated code.

@Native("BB")
class AA {
  get name => 'AA';
  static AA create() => makeA();
}

@Native("CC")
class BB {
  get name => 'BB';
  static BB create() => makeB();
}

class CC {  // Ordinary class with name clashing with native class.
  get name => 'CC';
  static CC create() => new CC();
}

makeA() native;
makeB() native;

void setup1() native """
// Poison hidden native names 'BB' and 'CC' to prove the compiler didn't place
// anthing on the hidden native class.
BB = null;
CC = null;
""";

void setup2() native """
// This code is all inside 'setup' and so not accesible from the global scope.
function BB(){}
function CC(){}
makeA = function(){return new BB};  // AA is native "BB"
makeB = function(){return new CC};  // BB is native "CC"
""";

int inscrutable(int x) => x == 0 ? 0 : x | inscrutable(x & (x - 1));

main() {
  setup1();
  setup2();

  var things = [AA.create(), BB.create(), CC.create()];
  var a = things[inscrutable(0)];
  var b = things[inscrutable(1)];
  var c = things[inscrutable(2)];

  Expect.equals('AA', a.name);
  Expect.equals('BB', b.name);
  Expect.equals('CC', c.name);
}
