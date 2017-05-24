// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test compile-time errors for illegal variable declarations if the name
// has been referenced before the variable is declared.

import 'dart:math' as math;

use(value) => value;

var x = 0;
final y = 0;

class C {
  var f;
  C() : f = 'How do you spell PTSD?';

  void test1() {
    use(f); // Refers to instance field f.
    var f = 'A shut mouth gathers no foot.'; // //# 00: compile-time error
  }

  void test2() {
    void localFunc() {
      use(f); // Refers to instance field f.
    }

    var f = 'When chemists die, they barium.'; // //# 01: compile-time error
    if (true) {
      var f = 1; // ok, shadows outer f and instance field f.
    }
  }

  void test3() {
    if (true) {
      use(x); // Refers to top-level x.
      use(y); // Refers to top-level y.
    }
    final x = "I have not yet begun to procrastinate."; // //# 02: compile-time error
    const y = "Honk if you like peace and quiet!"; // //# 03: compile-time error
  }

  void test4() {
    void Q() {
      P(); //# 06: compile-time error
    }
    void P() {
      Q();
    }

    Function f = () {x = f;}; // //# 07: compile-time error
  }

  test() {
    test1();
    test2();
    test3();
    test4();
  }
}

void testTypeRef() {
  String s = 'Can vegetarians eat animal crackers?';
  var String = "I distinctly remember forgetting that."; // //# 04: compile-time error
}

void testLibPrefix() {
  var pie = math.PI;
  final math = 0; // //# 05: compile-time error
}

void noErrorsExpected() {
  use(x);
  for (var x = 0; x < 10; x++) use(x);
  for (var i = 0; i < 10; i++) var x = 0;
  if (true) var x = 0;
  while (false) var x = 0;
  try {
    throw "ball";
  } catch (x) {
    use(x);
  }
  switch (x) {
    case 0:
      var x = 'Does fuzzy logic tickle?';
  }
  var int = 007;
}

void main() {
  var c = new C();
  c.test();
  testTypeRef();
  testLibPrefix();
  noErrorsExpected();
}
