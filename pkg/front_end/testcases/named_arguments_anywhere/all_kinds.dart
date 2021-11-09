// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A(int x, int y, {required int z});

  factory A.foo(int x, int y, {required int z}) => new A(x, y, z: z);

  void Function(int x, int y, {required int z}) get property => throw 42;

  void bar(int x, int y, {required int z}) {}
}

typedef B = A;

foo(int x, int y, {required int z}) {}

extension E on A {
  method1() {
    method2(foo: 1, 2); // This call.
  }
  method2(int bar, {int? foo}) {}
}

test(dynamic d, Function f, A a) {
  void local(int x, int y, {required int z}) {}

  // StaticInvocation.
  foo(1, 2, z: 3);
  foo(1, z: 2, 3);
  foo(z: 1, 2, 3);

  // FactoryConstructorInvocation.
  new A.foo(1, 2, z: 3);
  new A.foo(1, z: 2, 3);
  new A.foo(z: 1, 2, 3);
  new B.foo(1, 2, z: 3);
  new B.foo(1, z: 2, 3);
  new B.foo(z: 1, 2, 3);

  // ConstructorInvocation.
  new A(1, 2, z: 3);
  new A(1, z: 2, 3);
  new A(z: 1, 2, 3);
  new B(1, 2, z: 3);
  new B(1, z: 2, 3);
  new B(z: 1, 2, 3);

  // DynamicInvocation.
  d(1, 2, z: 3);
  d(1, z: 2, 3);
  d(z: 1, 2, 3);

  // FunctionInvocation.
  f(1, 2, z: 3);
  f(1, z: 2, 3);
  f(z: 1, 2, 3);

  // InstanceGetterInvocation.
  a.property(1, 2, z: 3);
  a.property(1, z: 2, 3);
  a.property(z: 1, 2, 3);

  // InstanceInvocation.
  a.bar(1, 2, z: 3);
  a.bar(1, z: 2, 3);
  a.bar(z: 1, 2, 3);

  // LocalFunctionInvocation.
  local(1, 2, z: 3);
  local(1, z: 2, 3);
  local(z: 1, 2, 3);
}

class Test extends A {
  Test() : super(1, 2, z: 3);

  test() {
    super.bar(1, 2, z: 3);
    super.bar(1, z: 2, 3);
    super.bar(z: 1, 2, 3);
  }
}

main() {}
