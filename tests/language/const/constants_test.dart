// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class C {
  factory C() => C._();

  C._();
}

const
// [error line 11, column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
t() => null;

const
// [error line 17, column 1, length 5]
// [analyzer] SYNTACTIC_ERROR.EXTRANEOUS_MODIFIER
// [cfe] Can't have modifier 'const' here.
get v => null;

main() {
  const
      dynamic x = t();
      //          ^^^
      // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
      // [cfe] Method invocation is not a constant expression.
  const y = const C();
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  //        ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //              ^
  // [cfe] Cannot invoke a non-'const' factory where a const expression is expected.
  const
      dynamic z = v;
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
      // [cfe] Constant evaluation error:
}
