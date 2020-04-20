// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests various super-calls.
// Class B requires super-mixin semantics (used in Flutter).

class Base1 {
  void foo<T>(T a1, int a2) {}
  get bar => 42;
  set bazz(int x) {}
}

class A extends Base1 {
  testSuperCall(int x) => super.foo<String>('a1', 2);
  testSuperTearOff() => super.foo;
  testSuperGet() => super.bar;
  testSuperCallViaGetter() => super.bar<int>('param');
  testSuperSet() {
    super.bazz = 3;
  }
}

abstract class Base2 {
  void foo<T>(String a1, T a2, int a3);
  get bar;
  set bazz(int x);
}

abstract class B extends Base2 {
  testSuperCall(int x) => super.foo<double>('a1', 3.14, 5);
  testSuperTearOff() => super.foo;
  testSuperGet() => super.bar;
  testSuperCallViaGetter() => super.bar<int>('param');
  testSuperSet() {
    super.bazz = 3;
  }
}

main() {}
