// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

abstract class A {
  A get a;
}

class B implements A {
  @override
  C get a => C();
}

class C implements A {
  @override
  B get a => B();
}

class D implements B, C {
  @override
  H get a => H();
}

class E implements B, C {
  @override
  H get a => H();
}

class F implements B, C {
  @override
  H get a => H();
}

class G implements B, C {
  @override
  H get a => H();
}

class H implements B, C {
  @override
  H get a => H();
}

void foo(int n, A a) {
  if (n > 0) {
    foo(n - 1, E());
    foo(n - 1, F());
    foo(n - 1, G());
    foo(n - 1, a.a);
  }
}

void main() {
  B();
  C();
  foo(2, D());
}
