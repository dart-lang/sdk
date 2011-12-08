
class AudioParam native "*AudioParam" {

  num defaultValue;

  num maxValue;

  num minValue;

  String name;

  int units;

  num value;

  void cancelScheduledValues(num startTime) native;

  void exponentialRampToValueAtTime(num value, num time) native;

  void linearRampToValueAtTime(num value, num time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  void setValueAtTime(num value, num time) native;

  void setValueCurveAtTime(Float32Array values, num time, num duration) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
