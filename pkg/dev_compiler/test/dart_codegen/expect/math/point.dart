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
  return new Point<T>(((__x0) => DEVC$RT.cast(__x0, num, T, "CompositeCast", """line 37, column 25 of dart:math/point.dart: """, __x0 is T, false))(x + other.x), ((__x1) => DEVC$RT.cast(__x1, num, T, "CompositeCast", """line 37, column 38 of dart:math/point.dart: """, __x1 is T, false))(y + other.y));
  }
 Point<T> operator -(Point<T> other) {
  return new Point<T>(((__x2) => DEVC$RT.cast(__x2, num, T, "CompositeCast", """line 46, column 25 of dart:math/point.dart: """, __x2 is T, false))(x - other.x), ((__x3) => DEVC$RT.cast(__x3, num, T, "CompositeCast", """line 46, column 38 of dart:math/point.dart: """, __x3 is T, false))(y - other.y));
  }
 Point<T> operator *(num factor) {
  return new Point<T>(((__x4) => DEVC$RT.cast(__x4, num, T, "CompositeCast", """line 59, column 25 of dart:math/point.dart: """, __x4 is T, false))(x * factor), ((__x5) => DEVC$RT.cast(__x5, num, T, "CompositeCast", """line 59, column 37 of dart:math/point.dart: """, __x5 is T, false))(y * factor));
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
   return ((__x6) => DEVC$RT.cast(__x6, num, T, "CompositeCast", """line 86, column 12 of dart:math/point.dart: """, __x6 is T, false))(dx * dx + dy * dy);
  }
}
