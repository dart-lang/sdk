// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.19

// SharedOptions=-Da=true -Db=false

import 'package:expect/expect.dart';

class Base {
  final int x;
  const Base(this.x);
}

class Child extends Base {
  static const Child A = Child._(const bool.fromEnvironment('a') ? 0 : 1);
  static const Child B = Child._(const bool.fromEnvironment('b') ? 0 : 2);

  const Child._(int x) : super(x);
}

int case1() {
  switch (null as dynamic) {
    case Child.A:
      return 1;
    default:
      return 2;
  }
}

class A {
  final int x;
  const A(this.x);

  static const A a1 = A(const bool.fromEnvironment('x') ? 0 : 1);
  static const A a2 = A(const bool.fromEnvironment('x') ? 0 : 2);
}

int case2() {
  switch (null as dynamic) {
    case A.a1:
      return 1;
    default:
      return 2;
  }
}

class B {
  final int x;
  const B(this.x);
}

int case3() {
  switch (null as dynamic) {
    case B(const bool.fromEnvironment('x') ? 0 : 1):
      return 1;
    default:
      return 2;
  }
}

void main() {
  Expect.equals(case1(), 2);
  Expect.equals(case2(), 2);
  Expect.equals(case3(), 2);
}
