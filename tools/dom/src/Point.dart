// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of html;

/**
 * A utility class for representing two-dimensional positions.
 */
class Point {
  final num x;
  final num y;

  const Point([num x = 0, num y = 0]): x = x, y = y;

  String toString() => '($x, $y)';

  bool operator ==(other) {
    if (other is !Point) return false;
    return x == other.x && y == other.y;
  }

  Point operator +(Point other) {
    return new Point(x + other.x, y + other.y);
  }

  Point operator -(Point other) {
    return new Point(x - other.x, y - other.y);
  }

  Point operator *(num factor) {
    return new Point(x * factor, y * factor);
  }

  /**
   * Returns the distance between two points.
   */
  double distanceTo(Point other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return sqrt(dx * dx + dy * dy);
  }

  /**
   * Returns the squared distance between two points.
   *
   * Squared distances can be used for comparisons when the actual value is not
   * required.
   */
  num squaredDistanceTo(Point other) {
    var dx = x - other.x;
    var dy = y - other.y;
    return dx * dx + dy * dy;
  }

  Point ceil() => new Point(x.ceil(), y.ceil());
  Point floor() => new Point(x.floor(), y.floor());
  Point round() => new Point(x.round(), y.round());

  /**
   * Truncates x and y to integers and returns the result as a new point.
   */
  Point toInt() => new Point(x.toInt(), y.toInt());
}
