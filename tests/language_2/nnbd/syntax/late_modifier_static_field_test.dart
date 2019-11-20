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
  static late int fieldWithInit = init();
  static late int fieldWithTrivialInit = 123;
  static late int? fieldWithNullInit = null;
  static late int fieldWithNoInit;
}

class B {
  static late int fieldWithInit = init();
}

class C {
  static late int? fieldWithInit = init();
}

main() {
  Expect.equals(0, initCalls);
  Expect.equals(123, A.fieldWithInit);
  Expect.equals(123, A.fieldWithTrivialInit);
  Expect.equals(null, A.fieldWithNullInit);
  Expect.throws(
      () => A.fieldWithNoInit, (error) => error is LateInitializationError);
  Expect.equals(1, initCalls);
  Expect.equals(123, A.fieldWithInit);
  Expect.equals(123, A.fieldWithTrivialInit);
  Expect.equals(null, A.fieldWithNullInit);
  Expect.throws(
      () => A.fieldWithNoInit, (error) => error is LateInitializationError);
  Expect.equals(1, initCalls);
  A.fieldWithInit = 456;
  A.fieldWithTrivialInit = 456;
  A.fieldWithNullInit = 456;
  A.fieldWithNoInit = 456;
  Expect.equals(1, initCalls);
  Expect.equals(456, A.fieldWithInit);
  Expect.equals(456, A.fieldWithTrivialInit);
  Expect.equals(456, A.fieldWithNullInit);
  Expect.equals(456, A.fieldWithNoInit);
  Expect.equals(1, initCalls);
  initCalls = 0;

  // Late, non-final, with init that's pre-empted by setter.
  Expect.equals(0, initCalls);
  B.fieldWithInit = 456;
  Expect.equals(0, initCalls);
  Expect.equals(456, B.fieldWithInit);
  Expect.equals(0, initCalls);

  // Late, non-final, with init that's pre-empted by null setter.
  Expect.equals(0, initCalls);
  C.fieldWithInit = null;
  Expect.equals(0, initCalls);
  Expect.equals(null, C.fieldWithInit);
  Expect.equals(0, initCalls);
}
