// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.7

// Requirements=nnbd-weak

// Test implicit casts and null conversions for boolean expressions
// in weak mode.

import 'package:expect/expect.dart';
import 'boolean_conversion_lib1.dart';

void main() {
  check(neverAsBoolean, null, Expect.throwsReachabilityError);

  check(booleanAsBoolean, null, Expect.throwsAssertionError);
  check(booleanAsBoolean, true, expectOk);
  check(booleanAsBoolean, false, expectOk);

  check(dynamicAsBoolean, null, Expect.throwsAssertionError);
  check(dynamicAsBoolean, true, expectOk);
  check(dynamicAsBoolean, false, expectOk);

  check(dynamicAsBoolean, "", Expect.throwsTypeError);
  check(dynamicAsBoolean, "true", Expect.throwsTypeError);
  check(dynamicAsBoolean, "null", Expect.throwsTypeError);
  check(dynamicAsBoolean, "undefined", Expect.throwsTypeError);
  check(dynamicAsBoolean, 0, Expect.throwsTypeError);
  check(dynamicAsBoolean, 1, Expect.throwsTypeError);
  check(dynamicAsBoolean, [true], Expect.throwsTypeError);
}
