// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for dart2js: we incorrectly modeled `super.x = rhs` as a
// call and not an assignment, so the type of the expression was incorrectly
// assumed to be the return type of the setter rather than the type of the rhs.
import 'package:expect/expect.dart';

abstract class A {
  set x(v) {}
  set z(v) {}
  set y(v) {
    return 'hi';
  }
}

class S extends A {
  var _x; //      was bad: inferred as null, than [null | int]
  var _y = ''; // was bad: inferred as String, rather than [String | int]
  var _z; //      was ok : inferred as [null | int]

  set x(v) {
    _x = super.x = v;
  }

  set z(v) {
    super.z = v;
    _z = v;
  }

  set y(v) {
    _y = super.y = v;
  }

  get isXNull => _x == null;
  get isZNull => _z == null;
}

main() {
  var s = new S()
    ..x = 2
    ..y = 2
    ..z = 2;
  Expect.equals(false, s.isXNull); //      was incorrectly optimized to 'true'
  Expect.equals(false, s._y is String); // was incorrectly optimized to 'true'
  Expect.equals(false, s.isZNull); //      prints false
}
