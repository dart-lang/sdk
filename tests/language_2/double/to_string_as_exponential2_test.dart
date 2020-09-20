// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 1.0;
  Expect.throwsRangeError(() => v.toStringAsExponential(-1));
  Expect.throwsRangeError(() => v.toStringAsExponential(21));
  v.toStringAsExponential(1.5);
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
  v.toStringAsExponential("string");
  //                      ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  v.toStringAsExponential("3");
  //                      ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}
