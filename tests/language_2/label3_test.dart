// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L: while (false) {
    if (true) break L;
  }
  // Illegal: L is out of scope.
  continue L;
//^^^^^^^^
// [analyzer] SYNTACTIC_ERROR.CONTINUE_OUTSIDE_OF_LOOP
// [cfe] A continue statement can't be used outside of a loop or switch statement.
//         ^
// [analyzer] COMPILE_TIME_ERROR.LABEL_UNDEFINED
// [cfe] Can't find label 'L'.
}
