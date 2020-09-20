// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A();
  A.foo();
}

class B extends A {
  B.c1()
      : super.foo

        ()

  ;

  B.foo();
  B.c2()
      : this.foo

        ()

  ;

  B.c3()
      : super

        ()

  ;

  B();
  B.c4()
      : this

        ()

  ;
}

main() {
  new B.c1();
  new B.c2();
  new B.c3();
  new B.c4();
}
