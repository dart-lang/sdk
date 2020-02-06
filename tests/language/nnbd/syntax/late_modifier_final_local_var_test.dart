// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
// VMOptions=--optimization_counter_threshold=10
import 'package:expect/expect.dart';

int initCalls = 0;
int init() {
  ++initCalls;
  return 123;
}

main() {
  for (int i = 0; i < 20; ++i) {
    late final int fieldWithInit = init();
    Expect.equals(0, initCalls);
    Expect.equals(123, fieldWithInit);
    Expect.equals(1, initCalls);
    Expect.equals(123, fieldWithInit);
    Expect.equals(1, initCalls);

    late final int fieldWithNoInit;
    Expect.throws(
      () => fieldWithNoInit,
      (error) => error is LateInitializationError,
    );
    // Confuse the definite assignment analysis.
    if (1 > 0) {
      fieldWithNoInit = 123;
    }
    Expect.equals(123, fieldWithNoInit);
    Expect.throws(
      () {
        fieldWithNoInit = 456;
      },
      (error) => error is LateInitializationError,
    );
    Expect.equals(123, fieldWithNoInit);
    initCalls = 0;
  }
}
