// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

int initCalls = 0;
int init() {
  ++initCalls;
  return 123;
}

class A {
  static late final int fieldWithInit = init();
  static late final int fieldWithTrivialInit = 123;
  static late final int? fieldWithNullInit = null;
  static late final int fieldWithNoInit;
}

main() {
  Expect.equals(0, initCalls);
  Expect.equals(123, A.fieldWithInit);
  Expect.equals(123, A.fieldWithTrivialInit);
  Expect.equals(null, A.fieldWithNullInit);
  Expect.equals(1, initCalls);
  Expect.equals(123, A.fieldWithInit);
  Expect.equals(123, A.fieldWithTrivialInit);
  Expect.equals(null, A.fieldWithNullInit);
  Expect.equals(1, initCalls);

  Expect.throws(
      () => A.fieldWithNoInit, (error) => error is LateInitializationError);
  A.fieldWithNoInit = 123;
  Expect.equals(123, A.fieldWithNoInit);
  Expect.throws(() => {A.fieldWithNoInit = 456},
      (error) => error is LateInitializationError);
  Expect.equals(123, A.fieldWithNoInit);
}
