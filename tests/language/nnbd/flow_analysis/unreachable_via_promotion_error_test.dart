// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that when a variable's type is promoted to `Never?`, the
// resulting code block is considered reachable by flow analysis.  This is in
// contrast to promotion to `Never`, which is considered unreachable.

// SharedOptions=--enable-experiment=non-nullable
void promoteViaIsCheck(Object x, Object? y) {
  if (x is! int) {
    if (y is Never?) {
      // Reachable
    } else {
      return;
    }
  }
  // Since the `y is Never?` branch was reachable, `x` is not promoted to `int`.
  x.isEven;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] unspecified
}

main() {
  promoteViaIsCheck(0, null);
}
