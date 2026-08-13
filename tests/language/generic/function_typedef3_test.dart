// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for a function type test that cannot be eliminated at compile time.

// This test validates the static errors for typedefs as per the code in
// function_typedef2_test.dart in language versions after the release of
// nonfunction type aliases (Dart 2.13).

import "package:expect/expect.dart";

class A {}

typedef int F();

typedef G = F;

typedef H = int;

typedef I = A;

typedef J = List<int>;

typedef K = Function(Function<A>(A<int>));
//                               ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Can't use type arguments with type variable 'A'.
typedef L = Function({x});
//                    ^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_CLASS
// [cfe] Type 'x' not found.
//                     ^
// [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
// [cfe] Expected an identifier, but got '}'.

typedef M = Function({int});
        //               ^
        // [analyzer] SYNTACTIC_ERROR.MISSING_IDENTIFIER
        // [cfe] Expected an identifier, but got '}'.

foo({bool int = false}) {}
main() {
  bool b = true;
  Expect.isFalse(b is L);
  Expect.isFalse(b is M);
  Expect.isTrue(foo is M);
}
