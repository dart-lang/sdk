// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a method is invoked whose return type is `Never?`,
// the resulting code block is considered reachable by flow analysis.

Never? neverQuestionFunction() => null;

void explicitNeverQuestionType(Object x, bool b) {
  if (x is! int) {
    if (b) {
      neverQuestionFunction();
    } else {
      return;
    }
  }
  // Since completion of `neverQuestionFunction` was reachable, `x` is not
  // promoted to `int`.
  x.isEven;
  //^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'isEven' isn't defined for the type 'Object'.
}

main() {
  explicitNeverQuestionType(0, true);
}
