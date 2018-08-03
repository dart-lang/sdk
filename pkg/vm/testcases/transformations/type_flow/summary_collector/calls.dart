// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void foo1(Object x) {}
  dynamic get foo2;
  set foo3(int x);
}

class B {
  void bar1(Object arg) {}
  dynamic get bar2 => null;
  set bar3(int y) {}
  int bar4;
}

class C {
  interfaceCalls(A aa, Object a2, Object a3, Object a4) {
    aa.foo1(new B());
    aa.foo3 = aa.foo2;
    a4 = aa.foo2(a2, a3, aa.foo1);
    return a4;
  }

  dynamicCalls(dynamic aa, Object a2, Object a3, Object a4) {
    aa.foo1(new B());
    aa.foo3 = aa.foo2;
    a4 = aa.foo2(a2, a3, aa.foo1);
    return a4;
  }
}

class D extends B {
  superCalls(Object a1, Object a2, Object a3, Object a4) {
    super.bar1(a1);
    super.bar3 = super.bar4;
    a4 = super.bar2(a2, a3, super.bar1);
    return a4;
  }
}

main() {}
