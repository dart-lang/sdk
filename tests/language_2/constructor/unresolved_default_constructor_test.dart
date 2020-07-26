// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test unresolved default constructor calls cause compilation errors.

import 'package:expect/expect.dart';

class A {
  A.named();
  static method() {}
}

main() {
  A.method();
  Expect.throws(() => new A());
  //                      ^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Method not found: 'A'.
}
