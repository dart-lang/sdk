part of dart.core;
 abstract class int extends num {external const factory int.fromEnvironment(String name, {
  int defaultValue}
);
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
 external static int parse(String source, {
  int radix, int onError(String source)}
);
}
