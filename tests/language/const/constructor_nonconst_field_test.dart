// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {
  final int i = f();
  //            ^
  // [cfe] Method invocation is not a constant expression.
  final int j = 1;
  const A();
//^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_FIELD_INITIALIZED_BY_NON_CONST
}

int f() {
  return 3;
}

main() {
  const A().j;
}
