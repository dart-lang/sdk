// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(https://github.com/dart-lang/sdk/issues/51557): Decide if the mixins
// being applied in this test should be "mixin", "mixin class" or the test
// should be left at 2.19.
// @dart=2.19

import 'package:expect/expect.dart';

void main() {
  // Getter `foo` returns `B._foo` that is coming from the mixin declaration.
  Expect.equals('B._foo', C0().foo);
  Expect.equals('B._foo', D0().foo);

  // When mixin application is in the same library as the declaration,
  // private symbol from the mixin declaration `B._foo` overrides `A._foo`.
  Expect.equals('B._foo', C()._foo);
  Expect.equals('B._foo', D()._foo);
  // Getter `foo` returns `B._foo` that is coming from the mixin declaration.
  Expect.equals('B._foo', C().foo);
  Expect.equals('B._foo', D().foo);

  // E overrides `_foo`.
  Expect.equals('E._foo', E()._foo);
}

class C0 = A0 with B;
class C = A with B;

class D0 extends A0 with B {}

class D extends A with B {}

class E extends A with B {
  String? _foo = 'E._foo';
}

class A0 {}

class A {
  String? _foo = 'A._foo';
}

class B {
  String? _foo = 'B._foo';
  String get foo => _foo!;
}
