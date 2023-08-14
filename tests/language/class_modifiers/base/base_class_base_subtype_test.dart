// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow subtypes of a base class or mixin to be base as well.

import 'package:expect/expect.dart';

base class BaseClass {
  int foo = 0;
}

base class A extends BaseClass {}

base class B implements BaseClass {
  int foo = 1;
}

base mixin BaseMixin {
  int foo = 0;
}

base class AMixin with BaseMixin {}

base class BMixin = Object with BaseMixin;

// Used for trivial runtime tests of the base subtypes.
base class AConcrete extends A {}

base class BConcrete extends B {}

base class AMixinConcrete extends AMixin {}

base class BMixinConcrete extends BMixin {}

main() {
  Expect.equals(0, AConcrete().foo);
  Expect.equals(1, BConcrete().foo);
  Expect.equals(0, AMixinConcrete().foo);
  Expect.equals(0, BMixinConcrete().foo);
}
