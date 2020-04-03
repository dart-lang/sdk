// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test optimization of modulo operator on Smi.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr

import "package:expect/expect.dart";

import "truncdiv_test.dart" as truncdiv_test show foo, foo2;

main() {
  Expect.throws<IntegerDivisionByZeroException>(() => truncdiv_test.foo(12, 0));
  Expect.throws<IntegerDivisionByZeroException>(() => truncdiv_test.foo2(0));
}
