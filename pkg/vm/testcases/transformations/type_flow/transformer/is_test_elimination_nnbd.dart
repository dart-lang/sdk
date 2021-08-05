// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests elimination of 'is' tests.

class A {}

class B extends A {
  void foo() {
    print('foo');
  }

  bool get bar => int.parse('1') == 1;
}

class C implements A {}

A obj = int.parse('2') == 2 ? C() : A();
A getObj() => obj;

void test1() {
  var x = getObj();
  if (x is B) {
    x.foo();
  }
}

void test2(x) {
  if (x is B && x.bar) {
    print('bye');
  }
}

void test3(x) {
  if (x is! B) {
    return;
  }
  print('bye');
}

test4() => (getObj() is B) ? 3 : 4;

void main() {
  test1();
  test2(obj);
  test3(obj);
  test4();
}
