// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test to make sure we catch assignments to final local variables.

main() {
  final x = 30;
  x = 0; //   //# 01: compile-time error
  x += 1; //  //# 02: compile-time error
  ++x; //     //# 03: compile-time error
  x++; //     //# 04: compile-time error
}
