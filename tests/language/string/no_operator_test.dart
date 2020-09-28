// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

main() {
  var x = "x";
  var y = "y";
  Expect.throws(() => x < y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '<' isn't defined for the class 'String'.
  Expect.throws(() => x <= y);
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '<=' isn't defined for the class 'String'.
  Expect.throws(() => x > y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '>' isn't defined for the class 'String'.
  Expect.throws(() => x >= y);
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '>=' isn't defined for the class 'String'.
  Expect.throws(() => x - y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '-' isn't defined for the class 'String'.
  Expect.throws(() => x * y);
  //                      ^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  Expect.throws(() => x / y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '/' isn't defined for the class 'String'.
  Expect.throws(() => x ~/ y);
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '~/' isn't defined for the class 'String'.
  Expect.throws(() => x % y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '%' isn't defined for the class 'String'.
  Expect.throws(() => x >> y);
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '>>' isn't defined for the class 'String'.
  Expect.throws(() => x << y);
  //                    ^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '<<' isn't defined for the class 'String'.
  Expect.throws(() => x & y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '&' isn't defined for the class 'String'.
  Expect.throws(() => x | y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '|' isn't defined for the class 'String'.
  Expect.throws(() => x ^ y);
  //                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '^' isn't defined for the class 'String'.
  Expect.throws(() => -x);
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator 'unary-' isn't defined for the class 'String'.
  Expect.throws(() => ~x);
  //                  ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_OPERATOR
  // [cfe] The operator '~' isn't defined for the class 'String'.
}
