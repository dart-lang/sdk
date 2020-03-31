// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bad {
  int foo = 0;
  final int bar =
      foo
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [cfe] Can't access 'this' in a field initializer to read 'foo'.
      -1;
  static const int toto =
      bar
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Can't access 'this' in a field initializer to read 'bar'.
//    ^^^
// [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
// [cfe] Getter not found: 'bar'.
      -3;
}

void use(x) {}

main() {
  use(new Bad().bar);
  use(Bad.toto);
}
