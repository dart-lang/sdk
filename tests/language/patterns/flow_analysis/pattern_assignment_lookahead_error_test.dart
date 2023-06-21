// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that the first phase of flow analysis (used for "lookahead" to see
// what variables are assigned inside loops and closures) properly detects
// variables assigned inside pattern assignments.

int f(int? i) {
  if (i == null) return 0;
  int k = 0;
  // `i` is promoted to non-nullable `int` now.
  for (int j = 0; j < 2; j++) {
    // `i` should be demoted at this point, because it's assigned later in the
    // loop, so this statement should be an error.
    k += i;
    //^
    // [cfe] A value of type 'num' can't be assigned to a variable of type 'int'.
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
    // [cfe] A value of type 'int?' can't be assigned to a variable of type 'num' because 'int?' is nullable and 'num' isn't.

    // Now assign a nullable value to `i`.
    (i,) = (null,);
  }
  return k;
}

void main() {
  print(f(0));
}
