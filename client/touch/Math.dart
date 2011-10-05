// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// TODO(jacobr): pick a better name. This was goog.math in Closure.
/**
 * Math utility functions originally from the closure Math library.
 */
class GoogleMath {
  /**
   * Takes a [value] and clamps it to within the bounds specified by
   * [min] and [max].
   */
  static num clamp(num value, num min, num max) {
    return Math.min(Math.max(value, min), max);
  }

  /**
   * Tests whether the two values are equal to each other, within a certain
   * tolerance to adjust for floating point errors.
   * The optional [tolerance] value d Defaults to 0.000001. If specified,
   * it should be greater than 0.
   * Returns whether [a] and [b] are nearly equal.
   */
  static bool nearlyEquals(num a, num b, [num tolerance = 0.000001]) {
    return (a - b).abs() <= tolerance;
  }
}
