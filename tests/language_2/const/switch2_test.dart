// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

int main() {
  var a = [1, 2, 3][2];
  switch (a) {
  //      ^
  // [analyzer] COMPILE_TIME_ERROR.SWITCH_EXPRESSION_NOT_ASSIGNABLE
    case 0.0:
    //   ^
    // [cfe] Type 'int' of the switch expression isn't assignable to the type 'double' of this case expression.
      print("illegal");
      break;
    case 1:
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_CASE_EXPRESSION_TYPES
      print("OK");
  }
}
