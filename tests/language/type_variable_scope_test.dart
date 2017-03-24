// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables referenced from within static members are malformed.

class Foo<T> {
  Foo() {}

  static
  Foo<T> //# 00: static type warning
      m(
    Foo<T> //# 01: static type warning
          f) {
    Foo<T> x = new Foo<String>(); //# 02: static type warning
    return new Foo<String>();
  }

  // T is in scope for a factory method.
  factory Foo.I(Foo<T> f) {
    Foo<T> x = f;
  }

  // T is not in scope for a static field.
  static Foo<T> f1; //# 03: static type warning

  static
  Foo<T> //# 04: static type warning
      get f {
    return new Foo<String>();
  }

  static void set f(
                    Foo<T> //# 05: static type warning
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
