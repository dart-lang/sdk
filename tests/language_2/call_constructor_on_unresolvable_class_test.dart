// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that calling a constructor of a class that cannot be resolved causes
// compile error.

import "package:expect/expect.dart";
import 'dart:math';

main() {
  new A(); //        //# 01: compile-time error
  new A.foo(); //    //# 02: compile-time error
  new lib.A(); //    //# 03: compile-time error
}
