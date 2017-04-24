// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "native_testing.dart";

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

class CC {
  // Ordinary class with name clashing with native class.
  get name => 'CC';
  static CC create() => new CC();
}

makeA() native;
makeB() native;

void setup1() native """
// Poison hidden native names 'BB' and 'CC' to prove the compiler didn't place
// anything on the hidden native class.
BB = null;
CC = null;
""";

void setup2() native """
// This code is all inside 'setup' and so not accessible from the global scope.
function BB(){}
function CC(){}
makeA = function(){return new BB};  // AA is native "BB"
makeB = function(){return new CC};  // BB is native "CC"
self.nativeConstructor(BB);
self.nativeConstructor(CC);
""";

main() {
  nativeTesting();
  setup1();
  setup2();

  var a = confuse(AA.create());
  var b = confuse(BB.create());
  var c = confuse(CC.create());

  Expect.equals('AA', a.name);
  Expect.equals('BB', b.name);
  Expect.equals('CC', c.name);
}
