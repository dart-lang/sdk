// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

foo(a, [b]) {}

bar(a, {b}) {}

class A {
  A();
  A.test(a, [b]);
}

class B {
  B()

  ;
}

class C extends A {
  C()

  ;
}

class D {
  D();
  D.test(a, {b});
}

class E extends D {
  E()

  ;
}

main() {

  new B();
  new C();

  new E();


}
