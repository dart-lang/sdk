// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Base<T1, T2> {
  T1 t1;
  T2 t2;

  Base() {
    print('Base: $T1, $T2');
  }
}

class A extends Base<int, String> {
  A(String s);
}

class B<T> extends Base<List<T>, String> {
  B() {
    print('B: $T');
  }
}

class C {
  C(String s) {
    print('C: $s');
  }
}

foo1() => new C('hello');

void foo2() {
  new A('hi');
  new B<int>();
}

void foo3<T>() {
  new B<List<T>>();
}

main() {
  foo1();
  foo2();
  foo3<String>();
}
