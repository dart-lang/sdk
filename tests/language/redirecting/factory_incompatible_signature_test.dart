// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that incompatible signatures in a forwarding factory
// constructor leads to a compile-time error.

import "package:expect/expect.dart";

class A {
  A(a, b);
  factory A.f() = A;
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.REDIRECT_TO_INVALID_FUNCTION_TYPE
  // [cfe] The constructor function type 'A Function(dynamic, dynamic)' isn't a subtype of 'A Function()'.
}

main() {
  new A.f();
}
