// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

int initCalls = 0;
double init() {
  ++initCalls;
  return 1.23;
}

class A {
  late double? fieldWithInit = init();
  late double fieldWithTrivialInit = 1.23;
  late double? fieldWithNullInit = null;
  late double fieldWithNoInit;
}

main() {
  // Late, non-final, with init.
  var a = A();
  Expect.equals(0, initCalls);
  Expect.equals(1.23, a.fieldWithInit);
  Expect.equals(1.23, a.fieldWithTrivialInit);
  Expect.equals(null, a.fieldWithNullInit);
  Expect.throws(
      () => a.fieldWithNoInit, (error) => error is LateInitializationError);
  Expect.equals(1, initCalls);
  Expect.equals(1.23, a.fieldWithInit);
  Expect.equals(1.23, a.fieldWithTrivialInit);
  Expect.equals(null, a.fieldWithNullInit);
  Expect.throws(
      () => a.fieldWithNoInit, (error) => error is LateInitializationError);
  Expect.equals(1, initCalls);
  a.fieldWithInit = 4.56;
  a.fieldWithTrivialInit = 4.56;
  a.fieldWithNullInit = 4.56;
  a.fieldWithNoInit = 4.56;
  Expect.equals(1, initCalls);
  Expect.equals(4.56, a.fieldWithInit);
  Expect.equals(4.56, a.fieldWithTrivialInit);
  Expect.equals(4.56, a.fieldWithNullInit);
  Expect.equals(4.56, a.fieldWithNoInit);
  Expect.equals(1, initCalls);
  initCalls = 0;

  // Late, non-final, with init that's pre-empted by setter.
  var b = A();
  Expect.equals(0, initCalls);
  b.fieldWithInit = 4.56;
  Expect.equals(0, initCalls);
  Expect.equals(4.56, b.fieldWithInit);
  Expect.equals(0, initCalls);

  // Late, non-final, with init that's pre-empted by null setter.
  var c = A();
  Expect.equals(0, initCalls);
  c.fieldWithInit = null;
  Expect.equals(0, initCalls);
  Expect.equals(null, c.fieldWithInit);
  Expect.equals(0, initCalls);
}
