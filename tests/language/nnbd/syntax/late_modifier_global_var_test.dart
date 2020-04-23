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

late int varWithInit = init();
late int varWithInit2 = init();
late int? varWithInit3 = init();
late int varWithTrivialInit = 123;
late int? varWithNullInit = null;
late int varWithNoInit;
late final int finalVarWithInit = init();
late final int finalVarWithTrivialInit = 123;
late final int? finalVarWithNullInit = null;
late final int finalVarWithNoInit;

main() {
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

  Expect.equals(0, initCalls);
  varWithInit2 = 456;
  Expect.equals(0, initCalls);
  Expect.equals(456, varWithInit2);
  Expect.equals(0, initCalls);

  Expect.equals(0, initCalls);
  varWithInit3 = null;
  Expect.equals(0, initCalls);
  Expect.equals(null, varWithInit3);
  Expect.equals(0, initCalls);

  Expect.equals(0, initCalls);
  Expect.equals(123, finalVarWithInit);
  Expect.equals(123, finalVarWithTrivialInit);
  Expect.equals(null, finalVarWithNullInit);
  Expect.equals(1, initCalls);
  Expect.equals(123, finalVarWithInit);
  Expect.equals(123, finalVarWithTrivialInit);
  Expect.equals(null, finalVarWithNullInit);
  Expect.equals(1, initCalls);

  Expect.throws(
      () => finalVarWithNoInit, (error) => error is LateInitializationError);
  finalVarWithNoInit = 123;
  Expect.equals(123, finalVarWithNoInit);
  Expect.throws(() => {finalVarWithNoInit = 456},
      (error) => error is LateInitializationError);
  Expect.equals(123, finalVarWithNoInit);
}
