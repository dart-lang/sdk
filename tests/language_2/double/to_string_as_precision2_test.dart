// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test basic integer operations.

import "package:expect/expect.dart";

main() {
  var v = 0.0;
  Expect.throwsRangeError(() => v.toStringAsPrecision(0));
  Expect.throwsRangeError(() => v.toStringAsPrecision(22));
  Expect.throwsArgumentError(() => v.toStringAsPrecision(null));
  v.toStringAsPrecision(1.5);
  //                    ^^^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
  v.toStringAsPrecision("string");
  //                    ^^^^^^^^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
  v.toStringAsPrecision("3");
  //                    ^^^
  // [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
}
