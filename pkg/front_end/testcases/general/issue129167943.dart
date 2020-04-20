// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {}

abstract class B {
  void foo(num x);
}

abstract class C implements B {
  void foo(covariant int x);
}

abstract class D1 implements A, C, B {
  void foo(covariant int x);
}

class D2 implements A, C, B {
  void foo(covariant int x) {}
}

abstract class D3 implements A, C, B {}

abstract class D4 implements A, C, B {
  void foo(int x);
}

abstract class D5 implements A, C, B {
  void foo(num x);
}

abstract class E {
  void set foo(num x);
}

abstract class G implements E {
  void set foo(covariant int x);
}

abstract class H1 implements A, E, G {
  void set foo(covariant int x);
}

class H2 implements A, E, G {
  void set foo(covariant int x) {}
}

abstract class H3 implements A, E, G {}

abstract class H4 implements A, E, G {
  void set foo(int x);
}

abstract class H5 implements A, E, G {
  void set foo(num x);
}

main() {}
