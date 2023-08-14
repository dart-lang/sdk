// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verifies that compiler doesn't omit initialization check for
// a late final field when inlining implicit setter in call specializer.
// Regression test for https://github.com/dart-lang/sdk/issues/52554.

// VMOptions=--no-use-osr --deterministic --optimization-counter-threshold=10

import 'package:expect/expect.dart';

class A {
  late final int fieldWithInit;
}

main() {
  for (int i = 0; i < 50; ++i) {
    final a = A();
    a.fieldWithInit = 456;
    Expect.throws(() => a.fieldWithInit = 789);
  }
}
