// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/flutter/flutter/issues/16182
// Verifies that TFA correctly handles calls via fields/getters.

import "package:expect/expect.dart";

bool ok = false;

class T1 {
  // Should be reachable.
  void doTest1() {
    ok = true;
  }
}

class A1 {
  late T1 foo;

  void call([a1, a2, a3, a4, a5]) {
    foo = a5;
  }
}

class B1 {
  A1 aa1 = new A1();
}

void test1() {
  B1 bb = new B1();
  bb.aa1(1, 2, 3, 4, new T1());

  ok = false;
  bb.aa1.foo.doTest1();
  Expect.isTrue(ok);
}

class T2 {
  // Should be reachable.
  void doTest2() {
    ok = true;
  }
}

class A2 {
  dynamic foo;

  void call([a1, a2, a3, a4, a5, a6]) {
    foo = a6;
  }
}

class B2Base {
  dynamic _aa = new A2();
  dynamic get aa2 => _aa;
}

class B2 extends B2Base {
  void doSuperCall() {
    super.aa2(1, 2, 3, 4, 5, new T2());
  }
}

void test2() {
  var bb = new B2();
  bb.doSuperCall();

  ok = false;
  bb.aa2.foo.doTest2();
  Expect.isTrue(ok);
}

class T3 {
  // Should be reachable.
  void doTest3() {
    ok = true;
  }
}

class A3 {
  dynamic foo;

  void call([a1, a2, a3, a4, a5, a6, a7]) {
    foo = a7;
  }
}

class B3 {
  A3 aa3 = new A3();
}

dynamic bb3 = new B3();
Function unknown3 = () => bb3;
getDynamic3() => unknown3.call();

void test3() {
  getDynamic3().aa3(1, 2, 3, 4, 5, 6, new T3());

  ok = false;
  bb3.aa3.foo.doTest3();
  Expect.isTrue(ok);
}

class T4 {
  // Should be reachable.
  void doTest4() {
    ok = true;
  }
}

class A4 {
  dynamic foo;

  void call([a1, a2, a3, a4, a5, a6, a7, a8]) {
    foo = a8;
  }
}

class B4 {
  dynamic _aa = new A4();
  dynamic get aa4 => _aa;
}

dynamic bb4 = new B4();
Function unknown4 = () => bb4;
getDynamic4() => unknown4.call();

void test4() {
  getDynamic4().aa4(1, 2, 3, 4, 5, 6, 7, new T4());

  ok = false;
  getDynamic4().aa4.foo.doTest4();
  Expect.isTrue(ok);
}

void main() {
  test1();
  test2();
  test3();
  test4();
}
