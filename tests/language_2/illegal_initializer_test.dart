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
  /* //# 01: syntax error
        ()
  */ //# 01: continued
  ;

  B.foo();
  B.c2()
      : this.foo
  /* //# 02: syntax error
        ()
  */ //# 02: continued
  ;

  B.c3()
      : super
  /* //# 03: syntax error
        ()
  */ //# 03: continued
  ;

  B();
  B.c4()
      : this
  /* //# 04: syntax error
        ()
  */ //# 04: continued
  ;
}

main() {
  new B.c1();
  new B.c2();
  new B.c3();
  new B.c4();
}
