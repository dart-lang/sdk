// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// A debug break is not valid Dart syntax unless --enable-debug-break.

test(i) {
  break "outside_loop"; // //# 02: compile-time error
  do {
    if (i > 15) {
      break "inside_loop"; // //# 03: compile-time error
    }
  } while (false);
}

void main() {
  break "gdb"; //  //# 01: compile-time error
  for (var i = 0; i < 20; i++) {
    test(i);
  }
}
