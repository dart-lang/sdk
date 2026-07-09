// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Based on tests/language/number/int64_literal_test.dart

const int i21 = 2097152;

void foo() {
  int minInt64Value = -1 * i21 * i21 * i21; // OK
  minInt64Value = -9223372036854775807 - 1; // OK
  minInt64Value = -9223372036854775808; // OK
  minInt64Value = -(9223372036854775808); // Error
  minInt64Value = -(0x8000000000000000); // OK
  minInt64Value = 0x8000000000000000; // OK
  minInt64Value = -0x8000000000000000; // OK

  int maxInt64Value = 1 * i21 * i21 * i21 - 1; // OK
  maxInt64Value = 9223372036854775807; // OK
  maxInt64Value = 9223372036854775807; // OK
  maxInt64Value = 9223372036854775808 - 1; // Error
  maxInt64Value = -9223372036854775808 - 1; // OK
  maxInt64Value = -9223372036854775809; // Error
  maxInt64Value = 0x8000000000000000 - 1; // OK
  maxInt64Value = -0x8000000000000000 - 1; // OK
  maxInt64Value = -0x8000000000000001; // Error
  maxInt64Value = -(0x8000000000000001); // OK
}
