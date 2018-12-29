// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N join_return_with_assignment`

int bar() {
  int a = 3;
  --a; // LINT
  return a;
}

int foo() {
  int a = 3;
  a++; // LINT
  return a;
}

int doubleFoo() {
  int a = 3;
  a += 5;
  a += 15; // OK
  return a;
}

class A {
  int _a;
  int get myA {
    _a ??= 0; // LINT
    return _a;
  }
}

class B {
  int _a;
  int get myA {
    if (_a == 0) {
      _a = 10; // LINT
      return _a;
    } else {
      _a += 5; // LINT
      return _a;
    }
  }
}

class C {
  final A a = A();
}

int unJoinablePropertyAccessReturn() {
  final C c1 = C();
  final C c2 = C();

  c2.a._a = 1; // OK
  return c1.a._a;
}

int joinablePropertyAccessReturn() {
  final C c1 = C();

  c1.a._a = 1; // LINT
  return c1.a._a;
}
