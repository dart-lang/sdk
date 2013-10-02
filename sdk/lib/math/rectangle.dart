// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
part of dart.math;

/**
 * A base class for representing two-dimensional axis-aligned rectangles.
 */
abstract class RectangleBase<T extends num> {
  const RectangleBase();

  /**
   * The x-coordinate of the left edge.
   */
  T get left;
  /**
   * The y-coordinate of the top edge.
   */
  T get top;
  /** The `width` of the rectangle. */
  T get width;
  /** The `height` of the rectangle. */
  T get height;

  /**
   * The number of units `right` of the origin where this rectangle's bottom
   * right corner can be found.
   */
  T get right => left + width;
  /**
   * The number of units below the origin where this rectangle's bottom
   * right corner can be found.
   */
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
   * Returns null if there is no intersection.
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
  bool intersects(Rectangle other) {
    return (left <= other.left + other.width && other.left <= left + width &&
        top <= other.top + other.height && other.top <= top + height);
  }

  /**
   * Returns a new rectangle which completely contains `this` and [other].
   */
  Rectangle<T> union(Rectangle<T> other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);

    var left = min(this.left, other.left);
    var top = min(this.top, other.top);

    return new Rectangle<T>(left, top, right - left, bottom - top);
  }

  /**
   * Tests whether `this` entirely contains [another].
   */
  bool contains(Rectangle another) {
    return left <= another.left &&
           left + width >= another.left + another.width &&
           top <= another.top &&
           top + height >= another.top + another.height;
  }

  /**
   * Tests whether `this` entirely contains a point.
   */
  bool containsPoint(Point another) {
    return another.x >= left &&
           another.x <= left + width &&
           another.y >= top &&
           another.y <= top + height;
  }

  Rectangle<int> ceil() => new Rectangle<int>(left.ceil(), top.ceil(),
      width.ceil(), height.ceil());
  Rectangle<int> floor() => new Rectangle<int>(left.floor(), top.floor(),
      width.floor(), height.floor());
  Rectangle<int> round() => new Rectangle<int>(left.round(), top.round(),
      width.round(), height.round());

  /**
   * Truncates coordinates to integers and returns the result as a new
   * rectangle.
   */
  Rectangle<int> truncate() => new Rectangle<int>(left.toInt(), top.toInt(),
      width.toInt(), height.toInt());

  Point<T> get topLeft => new Point<T>(this.left, this.top);
  Point<T> get bottomRight => new Point<T>(this.left + this.width,
      this.top + this.height);

  static List<T> _calculateVerticesFromPoints(Point<T> a, Point<T> b) {
    var left;
    var width;
    if (a.x < b.x) {
      left = a.x;
      width = b.x - left;
    } else {
      left = b.x;
      width = a.x - left;
    }
    var top;
    var height;
    if (a.y < b.y) {
      top = a.y;
      height = b.y - top;
    } else {
      top = b.y;
      height = a.y - top;
    }
    return [left, top, width, height];
  }
}


/**
 * A class for representing two-dimensional rectangles whose properties are
 * immutable.
 */
class Rectangle<T> extends RectangleBase<T> {
  final T left;
  final T top;
  final T width;
  final T height;

  const Rectangle(this.left, this.top, this.width, this.height);

  factory Rectangle.fromPoints(Point<T> a, Point<T> b) {
    var list = RectangleBase._calculateVerticesFromPoints(a, b);
    return new Rectangle<T>(list[0], list[1], list[2], list[3]);
  }
}
