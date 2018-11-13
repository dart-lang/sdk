// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {}

class T2 {}

class T3 {}

class A {
  foo() => new T1();
  bar() => new T2();
  bazz() => new T3();
}

class B {
  foo() => new T1();
  bar() => new T2();
  bazz() => new T3();
}

use_foo1(dynamic x) => x.foo();
use_foo2(dynamic x) => x.foo();

use_bar(dynamic x) => x.bar();

use_bazz(dynamic x) => x.bazz();

Function unknown;

getDynamic() => unknown.call();

allocateA() {
  new A();
}

allocateB() {
  new B();
}

main(List<String> args) {
  use_foo1(getDynamic()); // No classes with 'foo' selector.

  allocateA();

  use_foo2(getDynamic()); // Only A with 'foo' selector.
  use_bar(getDynamic()); // Only A with 'bar' selector.

  allocateB();

  use_bazz(getDynamic()); // A and B have 'bazz' selector.
}
