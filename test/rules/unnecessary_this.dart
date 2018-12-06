// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// test w/ `pub run test -N unnecessary_this`

void bar() {}

int x;

class Parent {
  int x, y;
  void bar() {}
  void foo() {}
}

class Child extends Parent {
  void SuperclassMethodWithTopLevelFunction() {
    this.bar(); // OK
  }

  void SuperclassMethodWithoutTopLevelFunction() {
    this.foo(); // LINT
  }

  void SuperclassVariableWithTopLevelVariable(int a) {
    this.x = a; // OK
  }

  void SuperclassVariableWithoutTopLevelVariable(int a) {
    this.y = a; // LINT
  }
}

void duplicate() {}

class A {
  num x, y;

  A(num x, num y) {
    this.x = x; // OK
    this.y = y; // OK
  }

  A.c1(num x, num y)
      : x = x, // OK
        this.y = y; // LINT

  A.bar(this.x, this.y);

  A.foo(num a, num b) {
    this.x = a; // LINT
    this.y = b; // LINT
    this.fooMethod(); // LINT
  }

  void bar2(int a) {
    print(a.toString());
  }

  void barMethod() {
    if (x == y) {
      // ignore: unused_element
      void fooMethod() {
        // local function
      }
      this.fooMethod(); // OK
    }
    this.fooMethod(); // LINT
  }

  void duplicate() {}

  void fooMethod() {
    [].forEach((e) {
      this.bar2(e); // LINT
      this.duplicate(); // LINT
    });
  }
}
