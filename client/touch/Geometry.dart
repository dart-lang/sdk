// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Represents a point in 2 dimensional space.
 */
class Coordinate {

  /**
   * X-value
   */
  num x;

  /**
   * Y-value
   */
  num y;

  Coordinate([num this.x = 0, num this.y = 0]) {
  }

  /**
   * Gets the coordinates of a touch's location relative to the window's
   * viewport. [input] is either a touch object or an event object.
   */
  Coordinate.fromClient(var input) : this(input.clientX, input.clientY);

  static Coordinate difference(Coordinate a, Coordinate b) {
    return new Coordinate(a.x - b.x, a.y - b.y);
  }

  static num distance(Coordinate a, Coordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  }

  bool operator ==(Coordinate other) {
    return other !== null && x == other.x && y == other.y;
  }

  static num squaredDistance(Coordinate a, Coordinate b) {
    final dx = a.x - b.x;
    final dy = a.y - b.y;
    return dx * dx + dy * dy;
  }

  static Coordinate sum(Coordinate a, Coordinate b) {
    return new Coordinate(a.x + b.x, a.y + b.y);
  }

  /**
   * Returns a new copy of the coordinate.
   */
  Coordinate clone() {
    return new Coordinate(x, y);
  }

  /**
   * Returns a nice string representing the coordinate.
   * @return {string} In the form (50, 73).
   */
  String toString() {
    return "(${x}, ${y})";
  }
}

/**
 * A utility class for representing two-dimensional sizes.
 */
class Size {
  num width;
  num height;

  Size(num this.width, num this.height) {
  }

  bool operator ==(Size other) {
    return other !== null && width == other.width && height == other.height;
  }

  /**
   * Returns the area of the size (width * height).
   */
  num area() {
    return width * height;
  }

  /**
   * Returns the ratio of the size's width to its height.
   */
  num aspectRatio() {
    return width / height;
  }

  /**
   * Clamps the width and height parameters upward to integer values.
   * Returns this size with ceil'd components.
   */
  Size ceil() {
    width = width.ceil();
    height = height.ceil();
    return this;
  }

  /**
   * Returns a new copy of the Size.
   */
  Size clone() {
    return new Size(width, height);
  }

  /**
   * Returns true if this Size is the same size or smaller than the
   * [target] size in both dimensions.
   */
  bool fitsInside(Size target) {
    return width <= target.width && height <= target.height;
  }

  /**
   * Clamps the width and height parameters downward to integer values.
   * Returns this size with floored components.
   */
  Size floor() {
    width = width.floor();
    height = height.floor();
    return this;
  }

  /**
   * Returns the longer of the two dimensions in the size.
   */
  num getLongest() {
    return Math.max(width, height);
  }

  /**
   * Returns the shorter of the two dimensions in the size.
   */
  num getShortest() {
    return Math.min(width, height);
  }

  /**
   * Returns true if the size has zero area, false if both dimensions
   *     are non-zero numbers.
   */
  bool isEmpty() {
    return area() == 0;
  }

  /**
   * Returns the perimeter of the size (width + height) * 2.
   */
  num perimeter() {
    return (width + height) * 2;
  }

  /**
   * Rounds the width and height parameters to integer values.
   * Returns this size with rounded components.
   */
  Size round() {
    width = width.round();
    height = height.round();
    return this;
  }

  /**
   * Scales the size uniformly by a factor.
   * [s] The scale factor.
   * Returns this Size object after scaling.
   */
  Size scale(num s) {
    width *= s;
    height *= s;
    return this;
  }

  /**
   * Uniformly scales the size to fit inside the dimensions of a given size. The
   * original aspect ratio will be preserved.
   *
   * This function assumes that both Sizes contain strictly positive dimensions.
   * Returns this Size object, after optional scaling.
   */
  Size scaleToFit(Size target) {
    num s = aspectRatio() > target.aspectRatio() ?
        target.width / width : target.height / height;
    return scale(s);
  }

  /**
   * Returns a nice string representing size.
   * Returns in the form (50 x 73).
   */
  String toString() {
    return "(${width} x ${height})";
  }
}

/**
 * Represents the interval { x | start <= x < end }.
 */
class Interval {

  final num start;
  final num end;

  Interval(num this.start, num this.end) {}

  num get length() {
    return end - start;
  }

  bool operator ==(Interval other) {
    return other !== null && other.start == start && other.end == end;
  }

  Interval union(Interval other) {
    return new Interval(Math.min(start, other.start),
                        Math.max(end, other.end));
  }

  bool contains(num value) {
    return value >= start && value < end;
  }

  String toString() {
    return '(${start}, ${end})';
  }
}
