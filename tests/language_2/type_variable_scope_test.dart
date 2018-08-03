// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables referenced from within static members are malformed.

class Foo<T> {
  Foo() {}

  static
  Foo<T> //# 00: compile-time error
      m(
    Foo<T> //# 01: compile-time error
          f) {
    Foo<T> x = new Foo<String>(); //# 02: compile-time error
    return new Foo<String>();
  }

  // T is in scope for a factory method.
  factory Foo.I(Foo<T> f) {
    Foo<T> x = f;
  }

  // T is not in scope for a static field.
  static Foo<T> f1; //# 03: compile-time error

  static
  Foo<T> //# 04: compile-time error
      get f {
    return new Foo<String>();
  }

  static void set f(
                    Foo<T> //# 05: compile-time error
      value) {}
}

abstract class I<T> {
  factory I(Foo<T> f) = Foo<T>.I;
}

main() {
  Foo.m(new Foo<String>());
  new I(new Foo<String>());
  Foo.f1 = new Foo<String>(); //# 03: continued
  var x = Foo.f;
  Foo.f = x;
}
