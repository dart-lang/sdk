// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class ClassAnnotation {
  const ClassAnnotation();
}

const classAnnotation = const ClassAnnotation();

class ClassAnnotation2 {
  const ClassAnnotation2();
}

class MethodAnnotation {
  final int x;
  const MethodAnnotation(this.x);
}

class TypedefAnnotation {
  final List<int> list;
  const TypedefAnnotation(this.list);
}

class VarAnnotation {
  const VarAnnotation();
}

class ParametrizedAnnotation<T> {
  final T foo;
  const ParametrizedAnnotation(this.foo);
}

@classAnnotation
class A {
  static void staticMethod() {}
}

@ClassAnnotation2()
class B {
  @MethodAnnotation(42)
  void instanceMethod() {}
}

@TypedefAnnotation([1, 2, 3])
typedef void SomeType<T>(List<T> arg);

int foo(SomeType<int> a) {
  @VarAnnotation()
  int x = 2;
  return x + 2;
}

@ParametrizedAnnotation(null)
main(List<String> args) {
  A.staticMethod();
  new B().instanceMethod();
  foo(null);
}
