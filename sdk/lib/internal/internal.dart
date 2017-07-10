// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart._internal;

import 'dart:collection';

import 'dart:core' hide Symbol;
import 'dart:core' as core;
import 'dart:math' show Random;

part 'iterable.dart';
part 'list.dart';
part 'print.dart';
part 'sort.dart';
part 'symbol.dart';

// Powers of 10 up to 10^22 are representable as doubles.
// Powers of 10 above that are only approximate due to lack of precission.
// Used by double-parsing.
const POWERS_OF_TEN = const [
  1.0, // 0
  10.0,
  100.0,
  1000.0,
  10000.0,
  100000.0, // 5
  1000000.0,
  10000000.0,
  100000000.0,
  1000000000.0,
  10000000000.0, // 10
  100000000000.0,
  1000000000000.0,
  10000000000000.0,
  100000000000000.0,
  1000000000000000.0, // 15
  10000000000000000.0,
  100000000000000000.0,
  1000000000000000000.0,
  10000000000000000000.0,
  100000000000000000000.0, // 20
  1000000000000000000000.0,
  10000000000000000000000.0,
];

/**
 * An [Iterable] of the UTF-16 code units of a [String] in index order.
 */
class CodeUnits extends UnmodifiableListBase<int> {
  /** The string that this is the code units of. */
  final String _string;

  CodeUnits(this._string);

  int get length => _string.length;
  int operator [](int i) => _string.codeUnitAt(i);

  static String stringOf(CodeUnits u) => u._string;
}

/// Marks a function as an external implementation ("native" in the Dart VM).
///
/// Provides a backend-specific String that can be used to identify the
/// function's implementation.
class ExternalName {
  final String name;
  const ExternalName(this.name);
}

// Shared hex-parsing utilities.

/// Parses a single hex-digit as code unit.
///
/// Returns a negative value if the character is not a valid hex-digit.
int hexDigitValue(int char) {
  assert(char >= 0 && char <= 0xFFFF);
  const int digit0 = 0x30;
  const int a = 0x61;
  const int f = 0x66;
  int digit = char ^ digit0;
  if (digit <= 9) return digit;
  int letter = (char | 0x20);
  if (a <= letter && letter <= f) return letter - (a - 10);
  return -1;
}

/// Parses two hex digits in a string.
///
/// Returns a negative value if either digit isn't valid.
int parseHexByte(String source, int index) {
  assert(index + 2 <= source.length);
  int digit1 = hexDigitValue(source.codeUnitAt(index));
  int digit2 = hexDigitValue(source.codeUnitAt(index + 1));
  return digit1 * 16 + digit2 - (digit2 & 256);
}
