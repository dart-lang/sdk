// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This test verifies that if a read is performed on a getter whose type is
// `Never?`, the resulting code block is considered reachable by flow analysis.

// SharedOptions=--enable-experiment=non-nullable

Never? get neverQuestionGetter => null;

void explicitNeverQuestionType(Object x, bool b) {
  if (x is! int) {
    if (b) {
      neverQuestionGetter;
    } else {
      return;
    }
  }
  // Since the read of `neverQuestionGetter` was reachable, `x` is not promoted
  // to `int`.
  x.isEven;
//  ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
// [cfe] unspecified
}

main() {
  explicitNeverQuestionType(0, true);
}
