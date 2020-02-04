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
    late int varWithInit = init();
    late int varWithTrivialInit = 123;
    late int? varWithNullInit = null;
    late int varWithNoInit;
    Expect.equals(0, initCalls);
    Expect.equals(123, varWithInit);
    Expect.equals(123, varWithTrivialInit);
    Expect.equals(null, varWithNullInit);
    Expect.throws(
        () => varWithNoInit, (error) => error is LateInitializationError);
    Expect.equals(1, initCalls);
    Expect.equals(123, varWithInit);
    Expect.equals(123, varWithTrivialInit);
    Expect.equals(null, varWithNullInit);
    Expect.throws(
        () => varWithNoInit, (error) => error is LateInitializationError);
    Expect.equals(1, initCalls);
    varWithInit = 456;
    varWithTrivialInit = 456;
    varWithNullInit = 456;
    varWithNoInit = 456;
    Expect.equals(1, initCalls);
    Expect.equals(456, varWithInit);
    Expect.equals(456, varWithTrivialInit);
    Expect.equals(456, varWithNullInit);
    Expect.equals(456, varWithNoInit);
    Expect.equals(1, initCalls);
    initCalls = 0;

    late int varWithInit2 = init();
    Expect.equals(0, initCalls);
    varWithInit2 = 456;
    Expect.equals(0, initCalls);
    Expect.equals(456, varWithInit2);
    Expect.equals(0, initCalls);

    late int? varWithInit3 = init();
    Expect.equals(0, initCalls);
    varWithInit3 = null;
    Expect.equals(0, initCalls);
    Expect.equals(null, varWithInit3);
    Expect.equals(0, initCalls);

    late int varWithCondInit = null ?? init();
    var lambda = () {
      Expect.equals(123, varWithCondInit);
      Expect.equals(1, initCalls);
    };
    lambda();
    lambda();
    lambda();
    initCalls = 0;

    if (true) late int varNotInBlock = init();
    Expect.equals(0, initCalls);
    initCalls = 0;
  }
}
