// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests cyclic reference to type variables in type expressions

class Base<T> {}

class Derived extends Base<Derived> {} // legal

typedef void funcType<
    T
extends T //# 01: compile-time error
    >(T arg);

class DerivedFunc extends Base<funcType<DerivedFunc>> {}

abstract class A<
    S
extends S //# 02: compile-time error
    > {
  S field;
}

abstract class B<U extends Base<U>> {
  // legal
  U field;
}

class C1<
    V
extends V // //# 03: compile-time error
    > {
  V field;
}

class C2<
    V
extends V // //# 04: compile-time error
    > implements A<V> {
  V field;
}

class D1<W extends Base<W>> {
  // legal
  W field;
}

class D2<W extends Base<W>> implements B<W> {
  //   legal
  W field;
}

class E<X extends Base<funcType<X>>> {
  // legal

  X field;
}

main() {
  new C1<int>();
  new C2<int>();
  new D1<Derived>();
  new D2<Derived>();
  new E<DerivedFunc>();
  funcType<Object> val = null;
}
