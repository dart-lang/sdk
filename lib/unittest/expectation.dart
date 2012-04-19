// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** This file is sourced by unittest.dart. It defines [Expectation]. */

/**
 * Wraps an value and provides methods that can be used to verify that the value
 * matches a given expectation.
 */
class Expectation {
  final _value;

  Expectation(this._value);

  /** Asserts that the value is equivalent to [expected]. */
  void equals(expected) {
    // Use the type-specialized versions when appropriate to give better
    // error messages.
    if (_value is String && expected is String) {
      Expect.stringEquals(expected, _value);
    } else if (_value is Map && expected is Map) {
      Expect.mapEquals(expected, _value);
    } else if (_value is Set && expected is Set) {
      Expect.setEquals(expected, _value);
    } else {
      Expect.equals(expected, _value);
    }
  }

  /**
   * Asserts that the difference between [expected] and the value is within
   * [tolerance]. If no tolerance is given, it is assumed to be the value 4
   * significant digits smaller than the expected value.
   */
  void approxEquals(num expected,
      [num tolerance = null, String reason = null]) {
    Expect.approxEquals(expected, _value, tolerance: tolerance, reason: reason);
  }

  /**
   * Asserts that two objects are same (using [:===:]).
   */
  void same(expected) {
    Expect.identical(_value, expected);
  }

  /** Asserts that the value is [null]. */
  void isNull() {
    Expect.equals(null, _value);
  }

  /** Asserts that the value is not [null]. */
  void isNotNull() {
    Expect.notEquals(null, _value);
  }

  /** Asserts that the value is [true]. */
  void isTrue() {
    Expect.equals(true, _value);
  }

  /** Asserts that the value is [false]. */
  void isFalse() {
    Expect.equals(false, _value);
  }

  /** Asserts that the value has the same elements as [expected]. */
  void equalsCollection(Collection expected) {
    Expect.listEquals(expected, _value);
  }

  /**
   * Checks that every element of [expected] is also in [actual], and that
   * every element of [actual] is also in [expected].
   */
  void equalsSet(Iterable expected) {
    Expect.setEquals(expected, _value);
  }
}
