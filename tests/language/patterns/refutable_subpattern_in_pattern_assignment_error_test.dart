// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that a pattern assignment containing an assigned variable inside a
// refutable subpattern reports an error (and doesn't crash the compiler).

void orPattern(Object? x, Object? y, List<Object?> list) {
  [x || y] = list;
  // [error column 4, length 6]
  // [analyzer] COMPILE_TIME_ERROR.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT
  // ^
  // [cfe] Refutable patterns can't be used in an irrefutable context.
}

void nullCheckPattern(Object? x, List<Object?> list) {
  [x?] = list;
  // [error column 4, length 2]
  // [analyzer] COMPILE_TIME_ERROR.REFUTABLE_PATTERN_IN_IRREFUTABLE_CONTEXT
  //^
  // [cfe] Refutable patterns can't be used in an irrefutable context.
}

main() {}
