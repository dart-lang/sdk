// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int counter = 1;

void reset() {
  counter = 1;
}

int t(int value) {
  if (counter != value) {
    throw 'Expected $counter, actual $value';
  }
  counter++;
  return value;
}

class A {
  A(int x, int y, {required int z});

  factory A.foo(int x, int y, {required int z}) => new A(x, y, z: z);

  void Function(int x, int y, {required int z}) get property =>
          (int x, int y, {required int z}) {};

  void bar(int x, int y, {required int z}) {}
}

typedef B = A;

foo(int x, int y, {required int z}) {}

extension E on int {
  method1() {
    reset();
    method2(foo: t(1), t(2)); // This call.

    reset();
    staticMethod2(foo: t(1), t(2));
  }

  method2(int bar, {int? foo}) {}

  static staticMethod2(int bar, {int? foo}) {}
}

test(dynamic d, Function f, A a) {
  void local(int x, int y, {required int z}) {}

  // StaticInvocation.
  reset();
  foo(t(1), t(2), z: t(3));
  reset();
  foo(t(1), z: t(2), t(3));
  reset();
  foo(z: t(1), t(2), t(3));

  // FactoryConstructorInvocation.
  reset();
  new A.foo(t(1), t(2), z: t(3));
  reset();
  new A.foo(t(1), z: t(2), t(3));
  reset();
  new A.foo(z: t(1), t(2), t(3));
  reset();
  new B.foo(t(1), t(2), z: t(3));
  reset();
  new B.foo(t(1), z: t(2), t(3));
  reset();
  new B.foo(z: t(1), t(2), t(3));

  // ConstructorInvocation.
  reset();
  new A(t(1), t(2), z: t(3));
  reset();
  new A(t(1), z: t(2), t(3));
  reset();
  new A(z: t(1), t(2), t(3));
  reset();
  new B(t(1), t(2), z: t(3));
  reset();
  new B(t(1), z: t(2), t(3));
  reset();
  new B(z: t(1), t(2), t(3));

  // DynamicInvocation.
  reset();
  d(t(1), t(2), z: t(3));
  reset();
  d(t(1), z: t(2), t(3));
  reset();
  d(z: t(1), t(2), t(3));

  // FunctionInvocation.
  reset();
  f(t(1), t(2), z: t(3));
  reset();
  f(t(1), z: t(2), t(3));
  reset();
  f(z: t(1), t(2), t(3));

  // InstanceGetterInvocation.
  reset();
  a.property(t(1), t(2), z: t(3));
  reset();
  a.property(t(1), z: t(2), t(3));
  reset();
  a.property(z: t(1), t(2), t(3));

  // InstanceInvocation.
  reset();
  a.bar(t(1), t(2), z: t(3));
  reset();
  a.bar(t(1), z: t(2), t(3));
  reset();
  a.bar(z: t(1), t(2), t(3));

  // LocalFunctionInvocation.
  reset();
  local(t(1), t(2), z: t(3));
  reset();
  local(t(1), z: t(2), t(3));
  reset();
  local(z: t(1), t(2), t(3));

  // Implicit extension instance call.
  reset();
  t(1).method2(foo: t(2), t(3));
  reset();
  t(1).method2(t(2), foo: t(3));

  // Explicit extension instance call.
  reset();
  E(t(1)).method2(foo: t(2), t(3));
  reset();
  E(t(1)).method2(t(2), foo: t(3));

  // Explicit extension static call.
  reset();
  E.staticMethod2(foo: t(1), t(2));
  reset();
  E.staticMethod2(t(1), foo: t(2));
}

class Test extends A {
  Test() : super(t(1), t(2), z: t(3));
  Test.c1() : super(t(1), z: t(2), t(3));
  Test.c2() : super(z: t(1), t(2), t(3));

  test() {
    reset();
    super.bar(t(1), t(2), z: t(3));
    reset();
    super.bar(t(1), z: t(2), t(3));
    reset();
    super.bar(z: t(1), t(2), t(3));
  }
}

main() {
  reset();
  Test().test();

  reset();
  Test.c1();
  reset();
  Test.c2();

  var a = A(-1, -1, z: -1);
  var f = (int x, int y, {required int z}) {};
  test(f, f, a);
  0.method1();
}
