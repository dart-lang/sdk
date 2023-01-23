// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=sealed-class

// Allow a sealed type to appear in the "on" clause of a mixin declaration in
// another library.

import "package:expect/expect.dart";
import 'sealed_class_mixin_on_lib.dart';

mixin MA on SealedClass {}
mixin MB on SealedClass {}

class C extends A with MA, MB {
  int foo = 0;
}

main() {
  var c = C();
  Expect.equals(0, c.foo);
}
