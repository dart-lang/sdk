// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' show Random;

/// A UUID generator.
///
/// The generated values are 128 bit numbers encoded in a specific string
/// format.
///
/// Generate a version 4 (random) uuid. This is a uuid scheme that only uses
/// random numbers as the source of the generated uuid.
// TODO: replace with a MUCH more simple, random string that matches
//               the use case.
String generateV4UUID() {
  int special = 8 + _random.nextInt(4);

  return '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}-'
      '${_bitsDigits(16, 4)}-'
      '4${_bitsDigits(12, 3)}-'
      '${_printDigits(special, 1)}${_bitsDigits(12, 3)}-'
      '${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}${_bitsDigits(16, 4)}';
}

final Random _random = new Random();

String _bitsDigits(int bitCount, int digitCount) =>
    _printDigits(_generateBits(bitCount), digitCount);

int _generateBits(int bitCount) => _random.nextInt(1 << bitCount);

String _printDigits(int value, int count) =>
    value.toRadixString(16).padLeft(count, '0');
