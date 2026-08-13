// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Mixing in a mixin class inside its library.

import 'package:expect/expect.dart';

mixin class Class {
  int foo = 0;
}

mixin Mixin {
  int foo = 0;
}

abstract class A with Class {}

class AImpl extends A {}

class B with Class {}

class C = Object with Class;

abstract class D with Class, Mixin {}

class DImpl extends D {}

class E with Class, Mixin {}

mixin class NamedMixinClassApplication = Object with Mixin;

class F with NamedMixinClassApplication {
  // To avoid runtime error with DDC until issue 50489 is fixed.
  int foo = 0;
}

main() {
  Expect.equals(0, AImpl().foo);
  Expect.equals(0, B().foo);
  Expect.equals(0, C().foo);
  Expect.equals(0, DImpl().foo);
  Expect.equals(0, E().foo);
  Expect.equals(0, F().foo);
}
