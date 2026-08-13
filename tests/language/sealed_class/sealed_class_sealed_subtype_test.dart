// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

// Used for trivial runtime tests of the sealed subtypes.
class AConcrete extends A {}

class BConcrete extends B {}

main() {
  var a = AConcrete();
  Expect.equals(0, a.foo);

  var b = BConcrete();
  Expect.equals(1, b.foo);
}
