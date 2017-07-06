// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of "dart:math";

/**
 * A utility class for representing two-dimensional positions.
 */
class Point<T extends num> {
  final T x;
  final T y;

  const Point(T x, T y)
      : this.x = x,
        this.y = y;

  String toString() => 'Point($x, $y)';

  /**
   * A `Point` is only equal to another `Point` with the same coordinates.
   *
   * This point is equal to `other` if, and only if,
   * `other` is a `Point` with
   * [x] equal to `other.x` and [y] equal to `other.y`.
   */
  bool operator ==(other) {
    if (other is! Point) return false;
    return x == other.x && y == other.y;
  }

  int get hashCode => _JenkinsSmiHash.hash2(x.hashCode, y.hashCode);

  /**
   * Add [other] to `this`, as if both points were vectors.
   *
   * Returns the resulting "vector" as a Point.
   */
  Point<T> operator +(Point<T> other) {
    return new Point<T>(x + other.x, y + other.y);
  }

  /**
   * Subtract [other] from `this`, as if both points were vectors.
   *
   * Returns the resulting "vector" as a Point.
   */
  Point<T> operator -(Point<T> other) {
    return new Point<T>(x - other.x, y - other.y);
  }

  /**
   * Scale this point by [factor] as if it were a vector.
   *
   * *Important* *Note*: This function accepts a `num` as its argument only so
   * that you can scale Point<double> objects by an `int` factor. Because the
   * star operator always returns the same type of Point that originally called
   * it, passing in a double [factor] on a `Point<int>` _causes_ _a_
   * _runtime_ _error_ in checked mode.
   */
  Point<T> operator *(num /*T|int*/ factor) {
    return new Point<T>(
        (x * factor) as dynamic/*=T*/, (y * factor) as dynamic/*=T*/);
  }

  /**
   * Get the straight line (Euclidean) distance between the origin (0, 0) and
   * this point.
   */
  double get magnitude => sqrt(x * x + y * y);

  /**
   * Returns the distance between `this` and [other].
   */
  double distanceTo(Point<T> other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /**
   * Returns the squared distance between `this` and [other].
   *
   * Squared distances can be used for comparisons when the actual value is not
   * required.
   */
  T squaredDistanceTo(Point<T> other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return dx * dx + dy * dy;
  }
}
