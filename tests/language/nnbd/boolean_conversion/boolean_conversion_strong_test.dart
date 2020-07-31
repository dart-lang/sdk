// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-strong

// Test implicit casts and null conversions for boolean expressions
// in strong mode.

import 'package:expect/expect.dart';
import 'boolean_conversion_lib1.dart';

void main() {
  check(booleanAsBoolean, true, expectOk);
  check(booleanAsBoolean, false, expectOk);

  check(dynamicAsBoolean, null, Expect.throwsTypeError);
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
