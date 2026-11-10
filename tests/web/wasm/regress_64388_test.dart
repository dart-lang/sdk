// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
  void bar() {}
}

void test1() {
  Object f = () => null;
  if (f is A Function()) {
    print(f().foo);
  }
}

void test2() {
  Object r = (null,);
  if (r is (A,)) {
    print(r.$1.bar);
  }
}

void main() {
  test1();
  test2();
}
