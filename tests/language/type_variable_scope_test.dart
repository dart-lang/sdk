// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks

// Test that type variables aren't in scope of static methods and factories.

class Foo<T> {
  // T is not in scope for a static method.
  static
  Foo<T> /// 00: compile-time error
  m(
    Foo<T> /// 01: compile-time error
    f) {
    I<T> x; /// 02: compile-time error
  }

  // T is in scope for a factory method.
  factory I(I<T> i) {
    I<T> x;
  }

  // T is not in scope for a static field.
  static Foo<T> f1; /// 03: compile-time error

  static
  Foo<T> /// 04: compile-time error
  get f() { return null; }

  static void set f(
                    Foo<T> /// 05: compile-time error
                    value) {}
}

interface I<T> default Foo<T> {
  I(I<T> i);
}

main() {
  Foo.m(null);
  new I(null);
}
