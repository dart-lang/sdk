// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart.math;

/**
 * A base class for representing two-dimensional axis-aligned rectangles.
 *
 * This rectangle uses a left-handed Cartesian coordinate system, with x
 * directed to the right and y directed down, as per the convention in 2D
 * computer graphics.
 *
 * See also:
 *    [W3C Coordinate Systems Specification](http://www.w3.org/TR/SVG/coords.html#InitialCoordinateSystem).
 */
abstract class _RectangleBase<T extends num> {
  const _RectangleBase();

  /** The x-coordinate of the left edge. */
  T get left;
  /** The y-coordinate of the top edge. */
  T get top;
  /** The `width` of the rectangle. */
  T get width;
  /** The `height` of the rectangle. */
  T get height;

  /** The x-coordinate of the right edge. */
  T get right => left + width;
  /** The y-coordinate of the bottom edge. */
  T get bottom => top + height;

  String toString() {
    return 'Rectangle ($left, $top) $width x $height';
  }

  bool operator ==(other) {
    if (other is !Rectangle) return false;
    return left == other.left && top == other.top && width == other.width &&
        height == other.height;
  }

  int get hashCode => _JenkinsSmiHash.hash4(left.hashCode, top.hashCode,
      width.hashCode, height.hashCode);

  /**
   * Computes the intersection of `this` and [other].
   *
   * The intersection of two axis-aligned rectangles, if any, is always another
   * axis-aligned rectangle.
   *
   * Returns the intersection of this and `other`, or `null` if they don't
   * intersect.
   */
  Rectangle<T> intersection(Rectangle<T> other) {
    var x0 = max(left, other.left);
    var x1 = min(left + width, other.left + other.width);

    if (x0 <= x1) {
      var y0 = max(top, other.top);
      var y1 = min(top + height, other.top + other.height);

      if (y0 <= y1) {
        return new Rectangle<T>(x0, y0, x1 - x0, y1 - y0);
      }
    }
    return null;
  }


  /**
   * Returns true if `this` intersects [other].
   */
  bool intersects(Rectangle<num> other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }

  /**
   * Returns a new rectangle which completely contains `this` and [other].
   */
  Rectangle<T> boundingBox(Rectangle<T> other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);

    var left = min(this.left, other.left);
    var top = min(this.top, other.top);

    return new Rectangle<T>(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether `this` entirely contains [another].
   */
  bool containsRectangle(Rectangle<num> another) {
    return left <= another.left &&
           left + width >= another.left + another.width &&
           top <= another.top &&
           top + height >= another.top + another.height;
  }

  /**
   * Tests whether [another] is inside or along the edges of `this`.
   */
  bool containsPoint(Point<num> another) {
    return another.x >= left &&
           another.x <= left + width &&
           another.y >= top &&
           another.y <= top + height;
  }

  Point<T> get topLeft => new Point<T>(this.left, this.top);
  Point<T> get topRight => new Point<T>(this.left + this.width, this.top);
  Point<T> get bottomRight => new Point<T>(this.left + this.width,
      this.top + this.height);
  Point<T> get bottomLeft => new Point<T>(this.left,
      this.top + this.height);
}


/**
 * A class for representing two-dimensional rectangles whose properties are
 * immutable.
 */
class Rectangle<T extends num> extends _RectangleBase<T> {
  final T left;
  final T top;
  final T width;
  final T height;

  const Rectangle(this.left, this.top, this.width, this.height);

  factory Rectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = min(a.x, b.x);
    T width = max(a.x, b.x) - left;
    T top = min(a.y, b.y);
    T height = max(a.y, b.y) - top;
    return new Rectangle<T>(left, top, width, height);
  }
}

/**
 * A class for representing two-dimensional axis-aligned rectangles with mutable
 * properties.
 */
class MutableRectangle<T extends num>  extends _RectangleBase<T>
    implements Rectangle<T> {
  T left;
  T top;
  T width;
  T height;

  MutableRectangle(this.left, this.top, this.width, this.height);

  factory MutableRectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = min(a.x, b.x);
    T width = max(a.x, b.x) - left;
    T top = min(a.y, b.y);
    T height = max(a.y, b.y) - top;
    return new MutableRectangle<T>(left, top, width, height);
  }
}
