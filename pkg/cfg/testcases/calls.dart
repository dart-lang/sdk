// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  void foo1(int a, {String b});
  int get foo2;
  set foo3(double c);
}

class B extends C {
  B(int x) : super(x, 42) {
    print(x);
  }

  void superCalls(int arg) {
    super.m1(arg);
    super.m3 = super.m2 + 42;
  }

  void m1(int a) {
    print(a + 1);
  }

  int get m2 => x + 1;
  set m3(int b) {
    y = b + 1;
  }
}

class C {
  final int x;
  int y = -1;
  C(this.x, this.y);

  void m1(int a) {
    print(a + 2);
  }

  int get m2 => x + 2;
  set m3(int b) {
    y = b + 2;
  }
}

void instanceCalls(A obj, A? obj2, int a, String b, double c) {
  obj.foo1(a);
  obj.foo1(a, b: b);
  final v = obj.foo2;
  if (obj2 != null) {
    if (obj == obj2) {
      obj.foo3 = c + v;
    }
  }
  print(obj.foo1);
}

int sField = 42;

void staticCalls(int a, Object b) {
  if (a > 0) {
    staticCalls(a - 1, b);
  }
  sField = sField + 1;
}

void dynamicCalls(dynamic x, dynamic y, dynamic z) {
  x.foo1(y, z);
  final v = y.bar;
  z.baz = v + 1;
}

void closureCalls(Function func1, int Function<T>(T, String) func2) {
  func1(1, 'a');
  func2<int>(2, 'b');

  void func3(int x) => print(x);
  func3(42);

  void func4<T>(T x) => print(x);
  func4('abc');

  () {
    print('hey');
  }();
}

void objectAllocation(int a) {
  final obj = B(a);
  obj.y += obj.x;
}

void main() {}
