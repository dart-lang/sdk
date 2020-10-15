// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.math;

/// A utility class for representing two-dimensional positions.
class Point<T extends num> {
  final T x;
  final T y;

  const Point(T x, T y)
      : this.x = x,
        this.y = y;

  String toString() => 'Point($x, $y)';

  /// Whether [other] is a point with the same coordinates as this point.
  ///
  /// Returns `true` if [other] is a [Point] with [x] and [y]
  /// coordinates equal to the corresponding coordiantes of this point,
  /// and `false` otherwise.
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  int get hashCode => SystemHash.hash2(x.hashCode, y.hashCode);

  /// Add [other] to `this`, as if both points were vectors.
  ///
  /// Returns the resulting "vector" as a Point.
  Point<T> operator +(Point<T> other) {
    return Point<T>((x + other.x) as T, (y + other.y) as T);
  }

  /// Subtract [other] from `this`, as if both points were vectors.
  ///
  /// Returns the resulting "vector" as a Point.
  Point<T> operator -(Point<T> other) {
    return Point<T>((x - other.x) as T, (y - other.y) as T);
  }

  /// Scale this point by [factor] as if it were a vector.
  ///
  /// *Important* *Note*: This function accepts a `num` as its argument only so
  /// that you can scale `Point<double>` objects by an `int` factor. Because the
  /// `*` operator always returns the same type of `Point` as it is called on,
  /// passing in a double [factor] on a `Point<int>` _causes_ _a_
  /// _runtime_ _error_.
  Point<T> operator *(num /*T|int*/ factor) {
    return Point<T>((x * factor) as T, (y * factor) as T);
  }

  /// Get the straight line (Euclidean) distance between the origin (0, 0) and
  /// this point.
  double get magnitude => sqrt(x * x + y * y);

  /// Returns the distance between `this` and [other].
  double distanceTo(Point<T> other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /// Returns the squared distance between `this` and [other].
  ///
  /// Squared distances can be used for comparisons when the actual value is not
  /// required.
  T squaredDistanceTo(Point<T> other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return (dx * dx + dy * dy) as T;
  }
}
