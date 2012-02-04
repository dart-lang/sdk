
class _AudioParamJs extends _DOMTypeJs implements AudioParam native "*AudioParam" {

  final num defaultValue;

  final num maxValue;

  final num minValue;

  final String name;

  final int units;

  num value;

  void cancelScheduledValues(num startTime) native;

  void exponentialRampToValueAtTime(num value, num time) native;

  void linearRampToValueAtTime(num value, num time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  void setValueAtTime(num value, num time) native;

  void setValueCurveAtTime(_Float32ArrayJs values, num time, num duration) native;
}
