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
    //  ^
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    var f = 'A shut mouth gathers no foot.';
    //  ^
    // [cfe] Can't declare 'f' because it was already used in this scope.
  }

  void test2() {
    void localFunc() {
      use(f); // Refers to instance field f.
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    }

    var f = 'When chemists die, they barium.';
    //  ^
    // [cfe] Can't declare 'f' because it was already used in this scope.
    if (true) {
      var f = 1; // ok, shadows outer f and instance field f.
    }
  }

  void test3() {
    if (true) {
      use(x); // Refers to top-level x.
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
      use(y); // Refers to top-level y.
      //  ^
      // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    }
    final x = "I have not yet begun to procrastinate.";
    //    ^
    // [cfe] Can't declare 'x' because it was already used in this scope.
    const y = "Honk if you like peace and quiet!";
    //    ^
    // [cfe] Can't declare 'y' because it was already used in this scope.
  }

  void test4() {
    void Q() {
      P(); // Refers to non-existing top-level function P
//    ^
// [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
// [cfe] The method 'P' isn't defined for the class 'C'.
    }
    void P() {
    //   ^
    // [cfe] Can't declare 'P' because it was already used in this scope.
      Q();
    }

    Function f = () {x = f;};
    //       ^
    // [cfe] Can't declare 'f' because it was already used in this scope.
    //                   ^
    // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
    //                   ^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
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
//^^^^^^
// [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  var String = "I distinctly remember forgetting that.";
  //  ^
  // [cfe] Can't declare 'String' because it was already used in this scope.
}

void testLibPrefix() {
  var pie = math.pi;
  //        ^^^^
  // [analyzer] COMPILE_TIME_ERROR.REFERENCED_BEFORE_DECLARATION
  final math = 0;
  //    ^
  // [cfe] Can't declare 'math' because it was already used in this scope.
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
