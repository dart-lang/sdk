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

main() {
  late final int fieldWithInit = init();
  Expect.equals(0, initCalls);
  Expect.equals(123, fieldWithInit);
  Expect.equals(1, initCalls);
  Expect.equals(123, fieldWithInit);
  Expect.equals(1, initCalls);

  late final int fieldWithNoInit;
  Expect.throws(
      () => fieldWithNoInit, (error) => error is LateInitializationError);
  fieldWithNoInit = 123;
  Expect.equals(123, fieldWithNoInit);
}
