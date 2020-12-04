// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_asserts

// Verify that only static members can be accessed in initializers, and this
// applies to asserts in initializers.

import 'package:expect/expect.dart';

class A {
  A.ok() : b = a;
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'a'.
  A.ko() : assert(a == null);
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.IMPLICIT_THIS_REFERENCE_IN_INITIALIZER
  // [cfe] Can't access 'this' in a field initializer to read 'a'.
  var a, b;
}

main() {
  new A.ok();
  new A.ko();
}
