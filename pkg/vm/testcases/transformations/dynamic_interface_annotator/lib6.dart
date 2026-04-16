// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void dcMethod1() {}
  void dcMethod2(String x, int y) {}
  int get dcGetter1 => 1;
  void set dcSetter1(int value) {}
  static void staticMethod1() {}

  A();
  factory A.factory() => A();
}

class A2 extends A {
  @override
  void dcMethod1() {
    print('1');
  }
}

class A3 implements A {
  @override
  void dcMethod1() {
    print('1');
  }

  @override
  void dcMethod2(String x, int y) {}
  @override
  int get dcGetter1 => 1;
  @override
  void set dcSetter1(int value) {}
}

class B {
  final int dcField1 = 1;
  int dcField2 = 1;

  void dcMethod3() {}
  void dcMethod4(String x, int y) {}
  int get dcGetter2 => 1;
  void set dcSetter2(int value) {}
}

class C {
  int _dcPrivateMethod1() => 1;
}

mixin D on C {
  int method1() => (this as dynamic)._dcPrivateMethod1();
}

class E {
  void dcMethod5() {}
  int get dcGetter3 => 1;
  void set dcSetter3(int value) {}
  final int dcField7 = 1;
  int dcField8 = 1;
  int dcField9 = 1; // unexposed
}
