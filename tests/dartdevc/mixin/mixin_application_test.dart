// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'mixin_declaration.dart';

void main() {
  // Getter `foo` returns `B._foo` that is coming from the mixin declaration.
  Expect.equals('B._foo', C0().foo);
  Expect.equals('B._foo', D0().foo);

  // When mixin application is in a separate library from the declaration,
  // private symbol from the current library is used to access `_foo`.
  Expect.equals('A._foo', C()._foo);
  Expect.equals('A._foo', D()._foo);
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
