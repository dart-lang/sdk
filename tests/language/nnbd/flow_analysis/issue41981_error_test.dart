// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that a block of code that results from promotion to the
// `Never` type cannot affect the "definitely unassigned" state of a late
// variable, because promotion to `Never` causes the code to be considered
// unreachable.

// SharedOptions=--enable-experiment=non-nullable

main() {
  late int i;
  Null n = null;
  if (n != null) {
    // n has type `Never`, so this code is unreachable.
    i = 42;
  }
  i; // Variable is definitely unassigned
//^
// [analyzer] COMPILE_TIME_ERROR.DEFINITELY_UNASSIGNED_LATE_LOCAL_VARIABLE
// [cfe] Late variable 'i' without initializer is definitely unassigned.
}
