part of dart.core;

abstract class num implements Comparable<num> {
  bool operator ==(Object other);
  int get hashCode;
  int compareTo(num other);
  num operator +(num other);
  num operator -(num other);
  num operator *(num other);
  num operator %(num other);
  double operator /(num other);
  int operator ~/(num other);
  num operator -();
  num remainder(num other);
  bool operator <(num other);
  bool operator <=(num other);
  bool operator >(num other);
  bool operator >=(num other);
  bool get isNaN;
  bool get isNegative;
  bool get isInfinite;
  bool get isFinite;
  num abs();
  num get sign;
  int round();
  int floor();
  int ceil();
  int truncate();
  double roundToDouble();
  double floorToDouble();
  double ceilToDouble();
  double truncateToDouble();
  num clamp(num lowerLimit, num upperLimit);
  int toInt();
  double toDouble();
  String toStringAsFixed(int fractionDigits);
  String toStringAsExponential([int fractionDigits]);
  String toStringAsPrecision(int precision);
  String toString();
  static num parse(String input, [num onError(String input)]) {
    String source = input.trim();
    num result = int.parse(source,
        onError: DDC$RT.wrap((dynamic f(dynamic __u9)) {
      dynamic c(dynamic x0) => ((__x8) => DDC$RT.cast(__x8, dynamic, int,
          "CastResult", """line 442, column 36 of dart:core/num.dart: """,
          __x8 is int, true))(f(x0));
      return f == null ? null : c;
    }, _returnNull, __t12, __t10, "Wrap",
        """line 442, column 36 of dart:core/num.dart: """,
        _returnNull is __t10));
    if (result != null) return result;
    result = double.parse(source, DDC$RT.wrap((dynamic f(dynamic __u15)) {
      dynamic c(dynamic x0) => ((__x14) => DDC$RT.cast(__x14, dynamic, double,
          "CastResult", """line 444, column 35 of dart:core/num.dart: """,
          __x14 is double, true))(f(x0));
      return f == null ? null : c;
    }, _returnNull, __t12, __t16, "Wrap",
        """line 444, column 35 of dart:core/num.dart: """,
        _returnNull is __t16));
    if (result != null) return result;
    if (onError == null) throw new FormatException(input);
    return onError(input);
  }
  static _returnNull(_) => null;
}
typedef int __t10(String __u11);
typedef dynamic __t12(dynamic __u13);
typedef double __t16(String __u17);
