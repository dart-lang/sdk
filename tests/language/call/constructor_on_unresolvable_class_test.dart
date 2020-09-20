// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that calling a constructor of a class that cannot be resolved causes
// compile error.

import "package:expect/expect.dart";
import 'dart:math';

main() {
  new A();
  //  ^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'A'.
  new A.foo();
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'A.foo'.
  new lib.A();
  //  ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CREATION_WITH_NON_TYPE
  // [cfe] Method not found: 'lib.A'.
}
