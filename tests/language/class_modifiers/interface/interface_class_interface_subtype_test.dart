// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow subtypes of an interface class or mixin to be interface as well.

import 'package:expect/expect.dart';

interface class InterfaceClass {
  int foo = 0;
}

interface class A extends InterfaceClass {}

interface class B implements InterfaceClass {
  int foo = 1;
}

// Used for trivial runtime tests of the interface subtypes.
class AConcrete extends A {}

class BConcrete extends B {}

main() {
  Expect.equals(0, AConcrete().foo);
  Expect.equals(1, BConcrete().foo);
}
