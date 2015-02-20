part of dart.core;

abstract class int extends num {
  @patch factory int.fromEnvironment(String name, {int defaultValue}) {
    throw new UnsupportedError(
        'int.fromEnvironment can only be used as a const constructor');
  }
  int operator &(int other);
  int operator |(int other);
  int operator ^(int other);
  int operator ~();
  int operator <<(int shiftAmount);
  int operator >>(int shiftAmount);
  bool get isEven;
  bool get isOdd;
  int get bitLength;
  int toUnsigned(int width);
  int toSigned(int width);
  int operator -();
  int abs();
  int get sign;
  int round();
  int floor();
  int ceil();
  int truncate();
  double roundToDouble();
  double floorToDouble();
  double ceilToDouble();
  double truncateToDouble();
  String toString();
  String toRadixString(int radix);
  @patch static int parse(String source,
      {int radix, int onError(String source)}) {
    return ((__x24) => DDC$RT.cast(__x24, dynamic, int, "CastGeneral",
        """line 246, column 12 of dart:core/int.dart: """, __x24 is int,
        true))(Primitives.parseInt(source, radix, onError));
  }
}
