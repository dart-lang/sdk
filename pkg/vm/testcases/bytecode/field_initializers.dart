// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  int foo1;
  int foo2 = null;
  int foo3 = 42;
  int foo4;
  int foo5 = 43;

  A(this.foo4) : foo5 = 44;
  A.constr2(int x, int y)
      : foo1 = x,
        foo5 = y + 1;

  A.redirecting1() : this(45);
  A.redirecting2(int a, int b, int c) : this.constr2(a, b * c);
}

class B extends A {
  int foo6 = 46;
  static int foo7 = 47;
  static const int foo8 = 48;

  B() : super(49);
  B.c2(int i, int j)
      : foo6 = 50,
        super.redirecting2(i, j, 51);
}

main() {}
