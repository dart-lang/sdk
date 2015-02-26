part of dart.math;
 class Point<T extends num> {final T x;
 final T y;
 const Point(T x, T y) : this.x = x, this.y = y;
 String toString() => 'Point($x, $y)';
 bool operator ==(other) {
  if (other is! Point) return false;
   return x == other.x && y == other.y;
  }
 int get hashCode => _JenkinsSmiHash.hash2(x.hashCode, y.hashCode);
 Point<T> operator +(Point<T> other) {
  return new Point<T>(x + other.x, y + other.y);
  }
 Point<T> operator -(Point<T> other) {
  return new Point<T>(x - other.x, y - other.y);
  }
 Point<T> operator *(num factor) {
  return new Point<T>(x * factor, y * factor);
  }
 double get magnitude => sqrt(x * x + y * y);
 double distanceTo(Point<T> other) {
  var dx = x - other.x;
   var dy = y - other.y;
   return sqrt(dx * dx + dy * dy);
  }
 T squaredDistanceTo(Point<T> other) {
  var dx = x - other.x;
   var dy = y - other.y;
   return ((__x0) => DDC$RT.cast(__x0, num, T, "CastGeneral", """line 86, column 12 of dart:math/point.dart: """, __x0 is T, false))(dx * dx + dy * dy);
  }
}
