// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.2

// This exercises code supported in version 3.2.

import 'package:expect/expect.dart';

sealed class M {}

class A extends M {}

class B extends M {}

class C extends M {}

class D implements A, B {}

method(M m) => switch (m) {
      A() as B => 0,
      B() => 1,
    };

main() {
  Expect.throws(() => method(A()));
  Expect.equals(1, method(B()));
  Expect.throws(() => method(C()));
  Expect.equals(0, method(D()));
}
