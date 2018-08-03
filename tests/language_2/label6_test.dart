// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L:
  while (false) {
    break; //# 01: ok
    break L; //# 02: ok
    void innerfunc() {
      // Illegal: jump target is outside of function
      if (true) break L; //# 03: compile-time error
    }

    innerfunc();
  }
}
