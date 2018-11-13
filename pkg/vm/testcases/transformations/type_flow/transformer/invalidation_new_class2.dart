// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class T1 {}

class T2 {}

abstract class A {
  foo();
}

class B extends A {
  foo() => new T1();
}

abstract class C implements B {}

class D {}

class E extends D with C {
  foo() => new T2();
}

class Intermediate {
  bar(A aa) => aa.foo();
}

use1(Intermediate i, A aa) => i.bar(aa);
use2(Intermediate i, A aa) => i.bar(aa);
use3(Intermediate i, A aa) => i.bar(aa);

Function unknown;

getDynamic() => unknown.call();

allocateB() {
  new B();
}

allocateE() {
  new E();
}

main(List<String> args) {
  use1(new Intermediate(), getDynamic()); // No subclasses of A allocated.

  allocateB();

  use2(new Intermediate(), getDynamic()); // Now B is allocated.

  allocateE();

  use3(new Intermediate(), getDynamic()); // Now E is also allocated.
}
