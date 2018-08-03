// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable_asserts

// Verify that only static members can be accessed in initializers, and this
// applies to asserts in initializers.

import 'package:expect/expect.dart';

class A {
  A.ok() : b = a; //# 01: compile-time error
  A.ko() : assert(a == null); //# 02: compile-time error
  var a, b;
}

main() {
  new A.ok(); //# 01: continued
  new A.ko(); //# 02: continued
}
