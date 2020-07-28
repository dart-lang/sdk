// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

// [NNBD non-migrated]: This test has no language/ counterpart. The static
// errors are just redundant tests of the static type system, and the runtime
// errors are redundant with to_string_as_precision2_runtime_test.dart.

import "package:expect/expect.dart";

main() {
  var v = 0.0;
  Expect.throwsRangeError(() => v.toStringAsPrecision(0));
  Expect.throwsRangeError(() => v.toStringAsPrecision(22));
  Expect.throwsArgumentError(() => v.toStringAsPrecision(null));
  v.toStringAsPrecision(1.5);
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
  v.toStringAsPrecision("string");
  //                    ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  v.toStringAsPrecision("3");
  //                    ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}
