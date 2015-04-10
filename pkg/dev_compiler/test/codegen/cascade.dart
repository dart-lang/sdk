// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  var x;
}

void test_closure_with_mutate() {
  var a = new A();
  a.x = () {
    print("hi");
    a = null;
  };
  a
    ..x()
    ..x();
  print(a);
}

void test_closure_without_mutate() {
  var a = new A();
  a.x = () {
    print(a);
  };
  a
    ..x()
    ..x();
  print(a);
}

void test_mutate_inside_cascade() {
  var a;
  a = new A()
    ..x = (a = null)
    ..x = (a = null);
  print(a);
}

void test_mutate_outside_cascade() {
  var a, b;
  a = new A()
    ..x = (b = null)
    ..x = (b = null);
  a = null;
  print(a);
}

void test_VariableDeclaration_single() {
  var a = []
    ..length = 2
    ..add(42);
  print(a);
}

void test_VariableDeclaration_last() {
  var a = 42,
      b = []
        ..length = 2
        ..add(a);
  print(b);
}

void test_VariableDeclaration_first() {
  var a = []
    ..length = 2
    ..add(3),
      b = 2;
  print(a);
}

void test_increment() {
  var a = new A();
  var y = a
    ..x += 1
    ..x -= 1;
}

class Base<T> {
  final List<T> x = <T>[];
}

class Foo extends Base<int> {
  void test_final_field_generic(t) {
    x..add(1)..add(2)..add(3)..add(4);
  }
}
