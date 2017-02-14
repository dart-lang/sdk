// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' hide Rectangle;
import 'dart:math' as math show Point, Rectangle, MutableRectangle;
import 'package:expect/expect.dart' show Expect;

void main() {
  verifyRectable(new Rectangle(1, 2, 3, 4));
}

void verifyRectable(math.Rectangle rect) {
  Expect.equals(1.0, rect.left.toDouble());
  Expect.equals(2.0, rect.top.toDouble());
  Expect.equals(4.0, rect.right.toDouble());
  Expect.equals(6.0, rect.bottom.toDouble());
}

class Rectangle<T extends num> implements math.MutableRectangle<T> {
  T left;
  T top;
  T width;
  T height;

  Rectangle(this.left, this.top, this.width, this.height);

  T get right => left + width;

  T get bottom => top + height;

  Point<T> get topLeft => new Point<T>(left, top);

  Point<T> get topRight => new Point<T>(right, top);

  Point<T> get bottomLeft => new Point<T>(left, bottom);

  Point<T> get bottomRight => new Point<T>(right, bottom);

  //---------------------------------------------------------------------------

  bool contains(num px, num py) {
    return left <= px && top <= py && right > px && bottom > py;
  }

  bool containsPoint(math.Point<num> p) {
    return contains(p.x, p.y);
  }

  bool intersects(math.Rectangle<num> r) {
    return left < r.right && right > r.left && top < r.bottom && bottom > r.top;
  }

  /// Returns a new rectangle which completely contains `this` and [other].

  Rectangle<T> boundingBox(math.Rectangle<T> other) {
    T rLeft = min(left, other.left);
    T rTop = min(top, other.top);
    T rRight = max(right, other.right);
    T rBottom = max(bottom, other.bottom);
    return new Rectangle<T>(rLeft, rTop, rRight - rLeft, rBottom - rTop);
  }

  /// Tests whether `this` entirely contains [another].

  bool containsRectangle(math.Rectangle<num> r) {
    return left <= r.left &&
        top <= r.top &&
        right >= r.right &&
        bottom >= r.bottom;
  }

  Rectangle<T> intersection(math.Rectangle<T> rect) {
    T rLeft = max(left, rect.left);
    T rTop = max(top, rect.top);
    T rRight = min(right, rect.right);
    T rBottom = min(bottom, rect.bottom);
    return new Rectangle<T>(rLeft, rTop, rRight - rLeft, rBottom - rTop);
  }
}
