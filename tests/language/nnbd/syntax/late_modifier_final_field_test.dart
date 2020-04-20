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

class Base {
  late final int fieldWithInit;
}

class A extends Base {
  late final int fieldWithInit = init();
  int get superFieldWithInit => super.fieldWithInit;
}

class B {
  late final int fieldWithNoInit;
}

main() {
  for (int i = 0; i < 20; ++i) {
    Base a = A();
    Expect.equals(0, initCalls);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(1, initCalls);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(1, initCalls);
    // Setting Base.fieldWithInit once is ok but causes no calls to init().
    a.fieldWithInit = 456;
    Expect.equals(456, (a as A).superFieldWithInit);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(1, initCalls);
    // Setting Base.fieldWithInit twice throws an error.
    Expect.throws(() => {a.fieldWithInit = 789},
        (error) => error is LateInitializationError);
    Expect.equals(1, initCalls);
    Expect.equals(123, a.fieldWithInit);
    Expect.equals(1, initCalls);
    initCalls = 0;

    Base a2 = A();
    Expect.equals(0, initCalls);
    // Setting Base.fieldWithInit once is ok but causes no calls to init().
    a2.fieldWithInit = 456;
    Expect.equals(456, (a as A).superFieldWithInit);
    Expect.equals(0, initCalls);
    // Setting Base.fieldWithInit twice throws an error.
    Expect.throws(() => {a2.fieldWithInit = 789},
        (error) => error is LateInitializationError);
    Expect.equals(0, initCalls);
    Expect.equals(123, a2.fieldWithInit);
    Expect.equals(456, (a as A).superFieldWithInit);
    Expect.equals(1, initCalls);

    B b = B();
    Expect.throws(
        () => b.fieldWithNoInit, (error) => error is LateInitializationError);
    b.fieldWithNoInit = 123;
    Expect.equals(123, b.fieldWithNoInit);
    Expect.throws(() => {b.fieldWithNoInit = 456},
        (error) => error is LateInitializationError);
    Expect.equals(123, b.fieldWithNoInit);
    initCalls = 0;
  }
}
