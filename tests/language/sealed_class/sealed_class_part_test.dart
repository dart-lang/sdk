// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow extending and implementing sealed classes in a part file of
// the same library

import "package:expect/expect.dart";
part 'sealed_class_part_lib.dart';

sealed class SealedClass {
  int foo = 0;
}

main() {
  var a = A();
  Expect.equals(0, a.foo);

  var b = B();
  Expect.equals(1, b.foo);
}
