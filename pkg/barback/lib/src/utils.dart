// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.utils;

/// Converts a number in the range [0-255] to a two digit hex string.
///
/// For example, given `255`, returns `ff`.
String byteToHex(int byte) {
  assert(byte >= 0 && byte <= 255);

  const DIGITS = "0123456789abcdef";
  return DIGITS[(byte ~/ 16) % 16] + DIGITS[byte % 16];
}