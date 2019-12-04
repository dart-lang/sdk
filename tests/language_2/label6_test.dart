// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L:
  while (false) {
    break;
    break L;
    void innerfunc() {
      // Illegal: jump target is outside of function
      if (true) break L;
      //        ^
      // [cfe] Can't break to 'L' in a different function.
      //              ^
      // [analyzer] COMPILE_TIME_ERROR.LABEL_IN_OUTER_SCOPE
    }

    innerfunc();
  }
}
