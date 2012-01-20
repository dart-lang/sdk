
class AudioParam native "*AudioParam" {

  num get defaultValue() native "return this.defaultValue;";

  num get maxValue() native "return this.maxValue;";

  num get minValue() native "return this.minValue;";

  String get name() native "return this.name;";

  int get units() native "return this.units;";

  num get value() native "return this.value;";

  void set value(num value) native "this.value = value;";

  void cancelScheduledValues(num startTime) native;

  void exponentialRampToValueAtTime(num value, num time) native;

  void linearRampToValueAtTime(num value, num time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) native;

  void setValueAtTime(num value, num time) native;

  void setValueCurveAtTime(Float32Array values, num time, num duration) native;

  var dartObjectLocalStorage;

  String get typeName() native;
}
