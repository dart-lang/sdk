part of dart.math;

abstract class _RectangleBase<T extends num> {
  const _RectangleBase();
  T get left;
  T get top;
  T get width;
  T get height;
  T get right => ((__x1) => DDC$RT.cast(__x1, num, T, "CastGeneral",
      """line 33, column 18 of dart:math/rectangle.dart: """, __x1 is T,
      false))(left + width);
  T get bottom => ((__x2) => DDC$RT.cast(__x2, num, T, "CastGeneral",
      """line 35, column 19 of dart:math/rectangle.dart: """, __x2 is T,
      false))(top + height);
  String toString() {
    return 'Rectangle ($left, $top) $width x $height';
  }
  bool operator ==(other) {
    if (other is! Rectangle) return false;
    return left == other.left &&
        top == other.top &&
        right == other.right &&
        bottom == other.bottom;
  }
  int get hashCode => _JenkinsSmiHash.hash4(
      left.hashCode, top.hashCode, right.hashCode, bottom.hashCode);
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
  bool intersects(Rectangle<num> other) {
    return (left <= other.left + other.width &&
        other.left <= left + width &&
        top <= other.top + other.height &&
        other.top <= top + height);
  }
  Rectangle<T> boundingBox(Rectangle<T> other) {
    var right = max(this.left + this.width, other.left + other.width);
    var bottom = max(this.top + this.height, other.top + other.height);
    var left = min(this.left, other.left);
    var top = min(this.top, other.top);
    return new Rectangle<T>(left, top, right - left, bottom - top);
  }
  bool containsRectangle(Rectangle<num> another) {
    return left <= another.left &&
        left + width >= another.left + another.width &&
        top <= another.top &&
        top + height >= another.top + another.height;
  }
  bool containsPoint(Point<num> another) {
    return another.x >= left &&
        another.x <= left + width &&
        another.y >= top &&
        another.y <= top + height;
  }
  Point<T> get topLeft => new Point<T>(this.left, this.top);
  Point<T> get topRight => new Point<T>(this.left + this.width, this.top);
  Point<T> get bottomRight =>
      new Point<T>(this.left + this.width, this.top + this.height);
  Point<T> get bottomLeft => new Point<T>(this.left, this.top + this.height);
}
class Rectangle<T extends num> extends _RectangleBase<T> {
  final T left;
  final T top;
  final T width;
  final T height;
  const Rectangle(this.left, this.top, T width, T height)
      : this.width = (width < 0) ? -width * 0 : width,
        this.height = (height < 0) ? -height * 0 : height;
  factory Rectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = ((__x3) => DDC$RT.cast(__x3, num, T, "CastGeneral",
        """line 167, column 14 of dart:math/rectangle.dart: """, __x3 is T,
        false))(min(a.x, b.x));
    T width = ((__x4) => DDC$RT.cast(__x4, num, T, "CastGeneral",
        """line 168, column 15 of dart:math/rectangle.dart: """, __x4 is T,
        false))(max(a.x, b.x) - left);
    T top = ((__x5) => DDC$RT.cast(__x5, num, T, "CastGeneral",
        """line 169, column 13 of dart:math/rectangle.dart: """, __x5 is T,
        false))(min(a.y, b.y));
    T height = ((__x6) => DDC$RT.cast(__x6, num, T, "CastGeneral",
        """line 170, column 16 of dart:math/rectangle.dart: """, __x6 is T,
        false))(max(a.y, b.y) - top);
    return new Rectangle<T>(left, top, width, height);
  }
}
class MutableRectangle<T extends num> extends _RectangleBase<T>
    implements Rectangle<T> {
  T left;
  T top;
  T _width;
  T _height;
  MutableRectangle(this.left, this.top, T width, T height)
      : this._width = (width < 0) ? _clampToZero(width) : width,
        this._height = (height < 0) ? _clampToZero(height) : height;
  factory MutableRectangle.fromPoints(Point<T> a, Point<T> b) {
    T left = ((__x7) => DDC$RT.cast(__x7, num, T, "CastGeneral",
        """line 228, column 14 of dart:math/rectangle.dart: """, __x7 is T,
        false))(min(a.x, b.x));
    T width = ((__x8) => DDC$RT.cast(__x8, num, T, "CastGeneral",
        """line 229, column 15 of dart:math/rectangle.dart: """, __x8 is T,
        false))(max(a.x, b.x) - left);
    T top = ((__x9) => DDC$RT.cast(__x9, num, T, "CastGeneral",
        """line 230, column 13 of dart:math/rectangle.dart: """, __x9 is T,
        false))(min(a.y, b.y));
    T height = ((__x10) => DDC$RT.cast(__x10, num, T, "CastGeneral",
        """line 231, column 16 of dart:math/rectangle.dart: """, __x10 is T,
        false))(max(a.y, b.y) - top);
    return new MutableRectangle<T>(left, top, width, height);
  }
  T get width => _width;
  void set width(T width) {
    if (width < 0) width = ((__x11) => DDC$RT.cast(__x11, num, T, "CastGeneral",
        """line 247, column 28 of dart:math/rectangle.dart: """, __x11 is T,
        false))(_clampToZero(width));
    _width = width;
  }
  T get height => _height;
  void set height(T height) {
    if (height < 0) height = ((__x12) => DDC$RT.cast(__x12, num, T,
        "CastGeneral", """line 263, column 30 of dart:math/rectangle.dart: """,
        __x12 is T, false))(_clampToZero(height));
    _height = height;
  }
}
num _clampToZero(num value) {
  assert(value < 0);
  return -value * 0;
}
