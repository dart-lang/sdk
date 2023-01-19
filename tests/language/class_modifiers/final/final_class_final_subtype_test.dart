// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow subtypes of a final class or mixin to be final as well.

import 'package:expect/expect.dart';

final class FinalClass {
  int foo = 0;
}
final class A extends FinalClass {}
final class B implements FinalClass {
  @override
  int foo = 1;
}

final mixin FinalMixin {
  int foo = 0;
}
final class C implements FinalMixin {
  @override
  int foo = 1;
}
final class AMixin with FinalMixin {}
final class BMixin = Object with FinalMixin;

// Used for trivial runtime tests of the final subtypes.
class AConcrete extends A {}
class BConcrete extends B {}
class CConcrete extends C {}
class AMixinConcrete extends AMixin {}
class BMixinConcrete extends BMixin {}

main() {
  Expect.equals(0, AConcrete().foo);
  Expect.equals(1, BConcrete().foo);
  Expect.equals(1, CConcrete().foo);
  Expect.equals(0, AMixinConcrete().foo);
  Expect.equals(0, BMixinConcrete().foo);
}