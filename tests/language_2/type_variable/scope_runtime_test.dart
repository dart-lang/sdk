// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that type variables referenced from within static members are malformed.

class Foo<T> implements I<T> {
  Foo() {}

  static

      m(

          f) {

    return new Foo<String>();
  }

  // T is in scope for a factory method.
  factory Foo.I(Foo<T> f) {
    Foo<T> x = f;
  }

  // T is not in scope for a static field.


  static

      get f {
    return new Foo<String>();
  }

  static void set f(

      value) {}
}

abstract class I<T> {
  factory I(Foo<T> f) = Foo<T>.I;
}

main() {
  Foo.m(new Foo<String>());
  new I(new Foo<String>());

  var x = Foo.f;
  Foo.f = x;
}
