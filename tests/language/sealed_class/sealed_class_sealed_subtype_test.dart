// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Allow subtypes of a sealed class or mixin to be sealed as well.
import "package:expect/expect.dart";

sealed class SealedClass {
  int foo = 0;
}
sealed class A extends SealedClass {}
sealed class B implements SealedClass {
  @override
  int foo = 1;
}

sealed mixin SealedMixin {
  int foo = 0;
}
sealed class AMixin with SealedMixin {}
sealed class BMixin = Object with SealedMixin;

// Used for trivial runtime tests of the sealed subtypes.
class AConcrete extends A {}
class BConcrete extends B {}
class AMixinConcrete extends AMixin {}
class BMixinConcrete extends BMixin {}

main() {
  var a = AConcrete();
  Expect.equals(0, a.foo);

  var b = BConcrete();
  Expect.equals(1, b.foo);

  var amixin = AMixinConcrete();
  Expect.equals(0, amixin.foo);

  var bmixin = BMixinConcrete();
  Expect.equals(0, bmixin.foo);
}