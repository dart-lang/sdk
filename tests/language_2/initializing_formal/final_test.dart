// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

import "package:expect/expect.dart";

class A {
  var x, y;
  // This should cause an error because `x` is final when accessed as an
  // initializing formal.
  A(this.x)
      : y = (() {
          x = 3;
//        ^
// [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL_LOCAL
// [cfe] Can't assign to the final variable 'x'.
        });
}

main() {}
