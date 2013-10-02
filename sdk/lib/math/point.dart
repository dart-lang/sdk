// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart.math;

/**
 * A utility class for representing two-dimensional positions.
 */
class Point<T extends num> {
  final T x;
  final T y;

  const Point([T x = 0, T y = 0]): this.x = x, this.y = y;

  String toString() => '($x, $y)';

  bool operator ==(other) {
    if (other is !Point) return false;
    return x == other.x && y == other.y;
  }

  int get hashCode => _JenkinsSmiHash.hash2(x.hashCode, y.hashCode);

  Point<T> operator +(Point<T> other) {
    return new Point<T>(x + other.x, y + other.y);
  }

  Point<T> operator -(Point<T> other) {
    return new Point<T>(x - other.x, y - other.y);
  }

  /**
   * Scale this point by [factor] as if it were a vector.
   *
   * *Important* *Note*: This function accepts a `num` as its argument only so
   * that you can scale Point<double> objects by an `int` factor. Because the
   * star operator always returns the same type of Point that originally called
   * it, passing in a double [factor] on a Point<int> _will_ _cause_ _a_
   * _runtime_ _error_ in checked mode.
   */
  Point<T> operator *(num factor) {
    return new Point<T>(x * factor, y * factor);
  }

  /**
   * Get the straight line (Euclidean) distance between the origin (0, 0) and
   * this point.
   */
  T get magnitude => sqrt(x * x + y * y);

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

  Point<int> ceil() => new Point<int>(x.ceil(), y.ceil());
  Point<int> floor() => new Point<int>(x.floor(), y.floor());
  Point<int> round() => new Point<int>(x.round(), y.round());

  /**
   * Truncates x and y to integers and returns the result as a new point.
   */
  Point<int> truncate() => new Point<int>(x.toInt(), y.toInt());
}
