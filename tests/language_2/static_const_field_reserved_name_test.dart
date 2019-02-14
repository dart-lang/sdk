// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for testing redefinition of reserved names as static const fields.
// Issue https://github.com/dart-archive/dev_compiler/issues/587

import "package:expect/expect.dart";

class Field {
  static const name = 'Foo';
}

class StaticConstFieldReservedNameTest {
  static testMain() {
    Expect.equals('Foo', Field.name);
  }
}

class Foo {
  int get foo => 42;
  static final baz = new Foo();
}

class Bar extends Foo {
  get foo => 123;
  Bar.baz();
}

void main() {
  StaticConstFieldReservedNameTest.testMain();

  // Regression test for https://github.com/dart-lang/sdk/issues/33621
  Expect.equals(Bar.baz().foo, 123);
}
