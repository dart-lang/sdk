// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioParamWrappingImplementation extends DOMWrapperBase implements AudioParam {
  AudioParamWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get defaultValue() { return _ptr.defaultValue; }

  num get maxValue() { return _ptr.maxValue; }

  num get minValue() { return _ptr.minValue; }

  String get name() { return _ptr.name; }

  int get units() { return _ptr.units; }

  num get value() { return _ptr.value; }

  void set value(num value) { _ptr.value = value; }

  void cancelScheduledValues(num startTime) {
    _ptr.cancelScheduledValues(startTime);
    return;
  }

  void exponentialRampToValueAtTime(num value, num time) {
    _ptr.exponentialRampToValueAtTime(value, time);
    return;
  }

  void linearRampToValueAtTime(num value, num time) {
    _ptr.linearRampToValueAtTime(value, time);
    return;
  }

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) {
    _ptr.setTargetValueAtTime(targetValue, time, timeConstant);
    return;
  }

  void setValueAtTime(num value, num time) {
    _ptr.setValueAtTime(value, time);
    return;
  }

  void setValueCurveAtTime(Float32Array values, num time, num duration) {
    _ptr.setValueCurveAtTime(LevelDom.unwrap(values), time, duration);
    return;
  }
}
