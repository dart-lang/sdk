// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Bug: 4254106 Constant constructors must have (implicit) const parameters.

class ConstCounter {
  const ConstCounter(int i)
      : nextValue_ = (
      //             ^
      // [cfe] Can't find ')' to match '('.

            // Incorrect assignment of a non-const function to a final field.
            () => i + 1;
//          ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
// [cfe] Not a constant expression.
//                     ^
// [analyzer] SYNTACTIC_ERROR.EXPECTED_TOKEN
  final nextValue_;
}

main() {
  const ConstCounter(3);
//^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
}
