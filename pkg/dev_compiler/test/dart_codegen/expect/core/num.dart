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
    _parseError = false;
    num result = int.parse(source, onError: _onParseErrorInt);
    if (!_parseError) return result;
    _parseError = false;
    result = double.parse(source, _onParseErrorDouble);
    if (!_parseError) return result;
    if (onError == null) throw new FormatException(input);
    return onError(input);
  }
  static bool _parseError = false;
  static int _onParseErrorInt(String _) {
    _parseError = true;
    return 0;
  }
  static double _onParseErrorDouble(String _) {
    _parseError = true;
    return 0.0;
  }
}
