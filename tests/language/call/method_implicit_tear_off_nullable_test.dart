// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

class B {}

class C {
  B call(B b) => b;
}

typedef B BToB(B x);

C? c = null;

void check(BToB f) {}

main() {
  // Nullable types cannot have their `.call` method implicitly torn off.
  check(c);
  //    ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] unspecified
}
