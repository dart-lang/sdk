// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Validate that assignment to a prefix is handled consistently with the
// following spec text from section 16.19 (Assignment):
//     Evaluation of an assignment a of the form v = e proceeds as follows:
//     Let d be the innermost declaration whose name is v or v=, if it exists.
//     If d is the declaration of a local variable, ...
//     If d is the declaration of a library variable, ...
//     Otherwise, if d is the declaration of a static variable, ...
//     Otherwise, if a ocurs inside a top level or static function (be it
//   function, method, getter, or setter) or variable initializer, evaluation
//   of a causes e to be evaluated, after which a NoSuchMethodError is thrown.
//     Otherwise, the assignment is equivalent to the assignment this.v = e.
//
// Therefore, if p is an import prefix, evaluation of "p = ..." should be
// equivalent to "this.p = ..." inside a method, and should produce a
// NoSuchMethodError outside a method.

import "package:expect/expect.dart";
import "empty_library.dart" as p;

class Base {
  var p;
}

class Derived extends Base {
  void f() {
    p = 1; Expect.equals(1, this.p); /// 01: ok
  }
}

bool gCalled = false;

g() {
  gCalled = true;
  return 1;
}

noMethod(e) => e is NoSuchMethodError;

main() {
  new Derived().f();
  Expect.throws(() { p = g(); }, noMethod); Expect.isTrue(gCalled); /// 02: static type warning
}
