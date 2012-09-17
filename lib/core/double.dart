// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart core library.

// TODO: Convert this abstract class into a concrete class double
// that uses the patch class functionality to account for the
// different platform implementations.

abstract class double extends num {
  static const double NAN = 0.0 / 0.0;
  static const double INFINITY = 1.0 / 0.0;
  static const double NEGATIVE_INFINITY = -INFINITY;

  // Specialization of super-interface. Double is contagious. We can therefore
  // specialize more methods than in other num sub-interfaces.
  abstract double remainder(num other);
  abstract double operator +(num other);
  abstract double operator -(num other);
  abstract double operator *(num other);
  abstract double operator %(num other);
  abstract double operator /(num other);
  abstract double operator ~/(num other);
  abstract double operator -();
  abstract double abs();
  abstract double round();
  abstract double floor();
  abstract double ceil();
  abstract double truncate();

  /**
   * Provide a representation of this [double] value.
   *
   * The representation is a number literal such that the closest double value
   * to the representation's mathematical value is this [double].
   *
   * Returns "NaN" for the Not-a-Number value.
   * Returns "Infinity" and "-Infinity" for positive and negative Infinity.
   * Returns "-0.0" for negative zero.
   *
   * It should always be the case that if [:d:] is a [double], then
   * [:d == double.parse(d.toString()):].
   */
  abstract String toString();

  /**
   * Parse [source] as an double literal and return its value.
   *
   * Accepts the same format as double literals:
   *   [: ['+'|'-'] [digit* '.'] digit+ [('e'|'E') ['+'|'-'] digit+] :]
   *
   * Also recognizes "NaN", "Infinity" and "-Infinity" as inputs and returns the
   * corresponding double value.
   * Throws a [FormatException] if [source] is not a valid double literal.
   */
  external static double parse(String source);
}
