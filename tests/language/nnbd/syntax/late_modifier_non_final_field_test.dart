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

class A {
  late int? fieldWithInit = init();
  late int fieldWithTrivialInit = 123;
  late int? fieldWithNullInit = null;
  late int fieldWithNoInit;
  late int? nullableFieldWithNoInit;
  late int? fieldWithOnlyCtorInit;
  late int? fieldWithOnlyBothInitAndCtorInit = 123;
  A()
      : fieldWithOnlyCtorInit = null,
        fieldWithOnlyBothInitAndCtorInit = null;
}

main() {
  for (int i = 0; i < 20; ++i) {
    // Late, non-final, with init.
    var a = A();
    Expect.equals(0, initCalls);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(123, a.fieldWithTrivialInit);
    Expect.equals(null, a.fieldWithNullInit);
    Expect.throws(
        () => a.fieldWithNoInit, (error) => error is LateInitializationError);
    Expect.throws(() => a.nullableFieldWithNoInit,
        (error) => error is LateInitializationError);
    Expect.equals(null, a.fieldWithOnlyCtorInit);
    Expect.equals(null, a.fieldWithOnlyBothInitAndCtorInit);
    Expect.equals(1, initCalls);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(123, a.fieldWithTrivialInit);
    Expect.equals(null, a.fieldWithNullInit);
    Expect.throws(
        () => a.fieldWithNoInit, (error) => error is LateInitializationError);
    Expect.throws(() => a.nullableFieldWithNoInit,
        (error) => error is LateInitializationError);
    Expect.equals(null, a.fieldWithOnlyCtorInit);
    Expect.equals(null, a.fieldWithOnlyBothInitAndCtorInit);
    Expect.equals(1, initCalls);
    a.fieldWithInit = 456;
    a.fieldWithTrivialInit = 456;
    a.fieldWithNullInit = 456;
    a.fieldWithNoInit = 456;
    a.nullableFieldWithNoInit = null;
    a.fieldWithOnlyCtorInit = 456;
    a.fieldWithOnlyBothInitAndCtorInit = 456;
    Expect.equals(1, initCalls);
    Expect.equals(456, a.fieldWithInit);
    Expect.equals(456, a.fieldWithTrivialInit);
    Expect.equals(456, a.fieldWithNullInit);
    Expect.equals(456, a.fieldWithNoInit);
    Expect.equals(null, a.nullableFieldWithNoInit);
    Expect.equals(456, a.fieldWithOnlyCtorInit);
    Expect.equals(456, a.fieldWithOnlyBothInitAndCtorInit);
    Expect.equals(1, initCalls);
    initCalls = 0;

    // Late, non-final, with init that's pre-empted by setter.
    var b = A();
    Expect.equals(0, initCalls);
    b.fieldWithInit = 456;
    Expect.equals(0, initCalls);
    Expect.equals(456, b.fieldWithInit);
    Expect.equals(0, initCalls);

    // Late, non-final, with init that's pre-empted by null setter.
    var c = A();
    Expect.equals(0, initCalls);
    c.fieldWithInit = null;
    Expect.equals(0, initCalls);
    Expect.equals(null, c.fieldWithInit);
    Expect.equals(0, initCalls);
    initCalls = 0;
  }
}
