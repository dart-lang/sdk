// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bad {
  int foo = 0;
  final int bar = foo - 1;
  //              ^^^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'foo'.
  static const int toto = bar - 3;
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'bar'.
  // [cfe] Not a constant expression.
}

void use(x) {}

main() {
  use(new Bad().bar);
  use(Bad.toto);
}
