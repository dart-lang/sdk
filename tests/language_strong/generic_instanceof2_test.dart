// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test that instanceof works correctly with type variables.

import "package:expect/expect.dart";

// Test that partially typed generic instances are correctly constructed.

// Test factory case.
class Foo<K, V> {
  Foo() {}

  factory Foo.fac() {
    return new Foo<K, V>();
  }

  FooString() {
    return new Foo<K, String>.fac();
  }
}

// Test constructor case.
class Moo<K, V> {
  Moo() {}

  MooString() {
    return new Moo<K, String>();
  }
}

testAll() {
  var foo_int_num = new Foo<int, num>();
  Expect.isTrue(foo_int_num is Foo<int, num>);
  Expect.isTrue(foo_int_num is! Foo<int, String>);
  // foo_int_num.FooString() returns a Foo<int, String>
  Expect.isTrue(foo_int_num.FooString() is! Foo<int, num>);
  Expect.isTrue(foo_int_num.FooString() is Foo<int, String>);

  var foo_raw = new Foo();
  Expect.isTrue(foo_raw is Foo<int, num>);
  Expect.isTrue(foo_raw is Foo<int, String>);
  // foo_raw.FooString() returns a Foo<dynamic, String>
  Expect.isTrue(foo_raw.FooString() is! Foo<int, num>);
  Expect.isTrue(foo_raw.FooString() is Foo<int, String>);

  var moo_int_num = new Moo<int, num>();
  Expect.isTrue(moo_int_num is Moo<int, num>);
  Expect.isTrue(moo_int_num is! Moo<int, String>);
  // moo_int_num.MooString() returns a Moo<int, String>
  Expect.isTrue(moo_int_num.MooString() is! Moo<int, num>);
  Expect.isTrue(moo_int_num.MooString() is Moo<int, String>);

  var moo_raw = new Moo();
  Expect.isTrue(moo_raw is Moo<int, num>);
  Expect.isTrue(moo_raw is Moo<int, String>);
  // moo_raw.MooString() returns a Moo<dynamic, String>
  Expect.isTrue(moo_raw.MooString() is! Moo<int, num>);
  Expect.isTrue(moo_raw.MooString() is Moo<int, String>);
}

main() {
  // Repeat type checks so that inlined tests can be tested as well.
  for (int i = 0; i < 5; i++) {
    testAll();
  }
}
