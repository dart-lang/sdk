// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a late variable might be read prior to its first
// assignment, but the semantics of local functions allow for the possibility
// that the assignment might occur before the read, that there is no
// compile-time error.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

// First scenario: the variable is written inside the function, and the read
// happens after the function is created.
void writeInFunction() {
  late int x;
  void f() {
    x = 10;
  }

  f();
  Expect.equals(x, 10);
}

void writeInClosure() {
  late int x;
  var f = () {
    x = 10;
  };
  f();
  Expect.equals(x, 10);
}

// Second scenario: the variable is written outside the function, and the read
// happens inside the function.
void readInFunction() {
  late int x;
  void f() {
    Expect.equals(x, 10);
  }

  x = 10;
  f();
}

void readInClosure() {
  late int x;
  var f = () {
    Expect.equals(x, 10);
  };
  x = 10;
  f();
}

main() {
  writeInFunction();
  writeInClosure();
  readInFunction();
  readInClosure();
}
