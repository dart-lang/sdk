// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test check that we catch label errors.

main() {
  if (true) {
    break;
//  ^^^^^
// [analyzer] SYNTACTIC_ERROR.BREAK_OUTSIDE_OF_LOOP
// [cfe] A break statement can't be used outside of a loop or switch statement.
  }
}
