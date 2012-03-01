
class _AudioParamImpl extends _DOMTypeBase implements AudioParam {
  _AudioParamImpl._wrap(ptr) : super._wrap(ptr);

  num get defaultValue() => _wrap(_ptr.defaultValue);

  num get maxValue() => _wrap(_ptr.maxValue);

  num get minValue() => _wrap(_ptr.minValue);

  String get name() => _wrap(_ptr.name);

  int get units() => _wrap(_ptr.units);

  num get value() => _wrap(_ptr.value);

  void set value(num value) { _ptr.value = _unwrap(value); }

  void cancelScheduledValues(num startTime) {
    _ptr.cancelScheduledValues(_unwrap(startTime));
    return;
  }

  void exponentialRampToValueAtTime(num value, num time) {
    _ptr.exponentialRampToValueAtTime(_unwrap(value), _unwrap(time));
    return;
  }

  void linearRampToValueAtTime(num value, num time) {
    _ptr.linearRampToValueAtTime(_unwrap(value), _unwrap(time));
    return;
  }

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) {
    _ptr.setTargetValueAtTime(_unwrap(targetValue), _unwrap(time), _unwrap(timeConstant));
    return;
  }

  void setValueAtTime(num value, num time) {
    _ptr.setValueAtTime(_unwrap(value), _unwrap(time));
    return;
  }

  void setValueCurveAtTime(Float32Array values, num time, num duration) {
    _ptr.setValueCurveAtTime(_unwrap(values), _unwrap(time), _unwrap(duration));
    return;
  }
}
