// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

void main() {
  var a = [1, 2, 3][2];
  switch (a) {
  //      ^
  // [analyzer] STATIC_WARNING.SWITCH_EXPRESSION_NOT_ASSIGNABLE
    case 0.0:
    //   ^
    // [cfe] Type 'double' of the case expression is not a subtype of type 'int' of this switch expression.
    //   ^
    // [cfe] Case expression '0.0' does not have a primitive operator '=='.
      print("illegal");
      break;
    case 1:
    //   ^
    // [analyzer] COMPILE_TIME_ERROR.INCONSISTENT_CASE_EXPRESSION_TYPES
      print("OK");
  }
}
