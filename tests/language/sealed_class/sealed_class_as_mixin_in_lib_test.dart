// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class,class-modifiers

// Allow mixing in a sealed class inside of library.

import "package:expect/expect.dart";

sealed class SealedClass {
  int foo = 0;
}
sealed mixin SealedMixin {}
class Class {
  int foo = 0;
}
mixin Mixin {}

abstract class A with SealedClass {}

class AImpl extends A {}

class B with SealedClass {}

abstract class C = Object with SealedClass;

class CImpl extends C {}

abstract class D with SealedClass, Class {}

class DImpl extends D {}

class E with Class, SealedMixin {}

abstract class F with Mixin, SealedClass {}

class FImpl extends F {}

main() {
  Expect.equals(0, AImpl().foo);
  Expect.equals(0, B().foo);
  Expect.equals(0, CImpl().foo);
  Expect.equals(0, DImpl().foo);
  Expect.equals(0, E().foo);
  Expect.equals(0, FImpl().foo);
}