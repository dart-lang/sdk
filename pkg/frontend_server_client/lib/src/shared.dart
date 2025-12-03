// Copyright 2020 The Dart Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:math' show Random;

import 'package:path/path.dart' as p;

final sdkDir = p.dirname(p.dirname(Platform.resolvedExecutable));
final sdkUri = p.toUri(sdkDir).toString();

/// Returns a unique ID in the format:
///
///     f47ac10b-58cc-4372-a567-0e02b2c3d479
///
/// The generated uuids are 128 bit numbers encoded in a specific string format.
/// For more information, see
/// [en.wikipedia.org/wiki/Universally_unique_identifier](http://en.wikipedia.org/wiki/Universally_unique_identifier).
String generateUuidV4() {
  final random = Random();

  int generateBits(int bitCount) => random.nextInt(1 << bitCount);

  String printDigits(int value, int count) =>
      value.toRadixString(16).padLeft(count, '0');
  String bitsDigits(int bitCount, int digitCount) =>
      printDigits(generateBits(bitCount), digitCount);

  // Generate xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx / 8-4-4-4-12.
  final special = 8 + random.nextInt(4);

  return '${bitsDigits(16, 4)}${bitsDigits(16, 4)}-'
      '${bitsDigits(16, 4)}-'
      '4${bitsDigits(12, 3)}-'
      '${printDigits(special, 1)}${bitsDigits(12, 3)}-'
      '${bitsDigits(16, 4)}${bitsDigits(16, 4)}${bitsDigits(16, 4)}';
}
