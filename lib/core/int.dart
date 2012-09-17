// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

abstract class int implements num {
  // Bit-operations.
  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);

  // Testers.
  bool isEven();
  bool isOdd();

  // Specializations of super-interface.
  int operator -();
  int abs();
  int round();
  int floor();
  int ceil();
  int truncate();
  /**
   * Returns a representation of this [int] value.
   *
   * It should always be the case that if 'i' is an [int] value, then
   * [:i == int.parse(i.toString())].
   */
  String toString();

  /**
   * Parse [source] as an integer literal and return its value.
   *
   * Accepts "0x" prefix for hexadecimal numbers, otherwise defaults
   * to base-10.
   * Throws a [FormatException] if [source] is not a valid integer literal.
   */
  external static int parse(String source);
}
