// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  L: while (false) {
    if (true) break L; //# 01: ok
  }
  // Illegal: L is out of scope.
  continue L; //# 02: compile-time error
}
