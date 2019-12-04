// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies constant propagation.

void test0(int arg) {
  print(arg);
}

void test1([int arg = 42]) {
  print(arg);
}

void test2({int arg = 43}) {
  print(arg);
}

get getD => 100.0;

void testDouble(double arg) {
  print(arg);
  print(getD);
}

class A {
  String get foo => 'foo';
  String getBar() => 'bar';
}

void testStrings(A a0, String a1) {
  print(a0.foo);
  print(a0.getBar());
  print(a1);
}

enum B { b1, b2, b3 }

void testPassEnum(B arg) {
  testPassEnum2(arg);
}

void testPassEnum2(B arg) {
  print(arg);
}

getList() => const [1, 2, 3];

void testList(arg1, [arg2 = const [4, 5]]) {
  print(arg1);
  print(arg2);
}

main() {
  test0(40);
  test1();
  test2();
  testDouble(3.14);
  testStrings(new A(), 'bazz');
  testPassEnum(B.b2);
  testList(getList());
}
