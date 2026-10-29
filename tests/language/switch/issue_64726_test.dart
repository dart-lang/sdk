// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that integer switches that compile to jump tables don't match values
// that are only in the table's range when truncated to 32 bits, and that
// switches whose case range overflows an int are compiled correctly.
//
// Regression test for https://github.com/dart-lang/sdk/issues/64726.

import "package:expect/expect.dart";

const twoTo32 = 0x100000000;

String switchFromZero(int value) => switch (value) {
  0 => 'zero',
  1 => 'one',
  2 => 'two',
  _ => 'default',
};

String switchFromNonZero(int value) {
  switch (value) {
    case 10:
      return 'ten';
    case 11:
      return 'eleven';
    case 12:
      return 'twelve';
    default:
      return 'default';
  }
}

String switchFromNegative(int value) => switch (value) {
  -2 => 'minus two',
  -1 => 'minus one',
  0 => 'zero',
  _ => 'default',
};

// The range of these cases is too large to fit in an int.
String switchWithHugeRange(int value) => switch (value) {
  -0x4000000000000000 => 'min',
  0x4000000000000000 => 'max',
  _ => 'default',
};

void main() {
  for (final value in [0, 1, 2]) {
    Expect.notEquals('default', switchFromZero(value));
  }
  for (final value in [
    -1,
    3,
    twoTo32,
    twoTo32 + 1,
    twoTo32 + 2,
    -twoTo32,
    -twoTo32 + 1,
  ]) {
    Expect.equals('default', switchFromZero(value), '$value');
  }

  for (final value in [10, 11, 12]) {
    Expect.notEquals('default', switchFromNonZero(value));
  }
  for (final value in [
    9,
    13,
    twoTo32 + 10,
    twoTo32 + 11,
    10 - twoTo32,
    12 - twoTo32,
  ]) {
    Expect.equals('default', switchFromNonZero(value), '$value');
  }

  for (final value in [-2, -1, 0]) {
    Expect.notEquals('default', switchFromNegative(value));
  }
  for (final value in [
    -3,
    1,
    twoTo32 - 2,
    twoTo32 - 1,
    twoTo32,
    -twoTo32 - 1,
    -twoTo32,
  ]) {
    Expect.equals('default', switchFromNegative(value), '$value');
  }

  Expect.equals('min', switchWithHugeRange(-0x4000000000000000));
  Expect.equals('max', switchWithHugeRange(0x4000000000000000));
  for (final value in [0, 1, -1, twoTo32]) {
    Expect.equals('default', switchWithHugeRange(value), '$value');
  }
}
