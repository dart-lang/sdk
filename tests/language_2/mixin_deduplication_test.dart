// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test mixin de-duplication with new mixin syntax.

import 'package:expect/expect.dart';

class A {
  int foo() => 1;
}

class B {
  int bar() => 2;
}

abstract class C implements A, B {
}

mixin M1 on A, B {
  int sum() => foo() + bar();
}

mixin M2 on A, B, M1 {
  int sumX2() => sum()*2;
}

class X extends C with M1, M2 {
  int foo() => 4;
  int bar() => 5;
}

class Y extends C with M1, M2 {
  int foo() => 7;
  int bar() => 10;
}

X x = new X();
Y y = new Y();

void main() {
  Expect.equals(9, x.sum());
  Expect.equals(18, x.sumX2());
  Expect.equals(17, y.sum());
  Expect.equals(34, y.sumX2());
}
