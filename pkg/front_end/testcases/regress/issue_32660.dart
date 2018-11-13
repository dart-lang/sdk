// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  foo(int x) => x;
}

class B {
  foo(int x, {int y}) => y;
}

class C extends A implements B {
  noSuchMethod(i) {
    print("No such method!");
    return 42;
  }
}

class D {
  foo(int x) => x;
}

class E extends D {
  foo(int x, {int y});

  noSuchMethod(i) {
    print(i.namedArguments);
    return 42;
  }
}

main() {
  C c = new C();
  E e = new E();
}
