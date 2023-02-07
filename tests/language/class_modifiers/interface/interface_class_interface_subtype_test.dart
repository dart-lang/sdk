// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=class-modifiers

// Allow subtypes of an interface class or mixin to be interface as well.

import 'package:expect/expect.dart';

interface class InterfaceClass {
  int foo = 0;
}
interface class A extends InterfaceClass {}
interface class B implements InterfaceClass {
  int foo = 1;
}

interface mixin InterfaceMixin {
  int foo = 0;
}
interface class AMixin with InterfaceMixin {}
interface class BMixin = Object with InterfaceMixin;

// Used for trivial runtime tests of the interface subtypes.
class AConcrete extends A {}
class BConcrete extends B {}
class AMixinConcrete extends AMixin {}
class BMixinConcrete extends BMixin {}

main() {
  Expect.equals(0, AConcrete().foo);
  Expect.equals(1, BConcrete().foo);
  Expect.equals(0, AMixinConcrete().foo);
  Expect.equals(0, BMixinConcrete().foo);
}
