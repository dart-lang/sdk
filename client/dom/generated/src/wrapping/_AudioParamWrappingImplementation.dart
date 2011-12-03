// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioParamWrappingImplementation extends DOMWrapperBase implements AudioParam {
  _AudioParamWrappingImplementation() : super() {}

  static create__AudioParamWrappingImplementation() native {
    return new _AudioParamWrappingImplementation();
  }

  num get defaultValue() { return _get_defaultValue(this); }
  static num _get_defaultValue(var _this) native;

  num get maxValue() { return _get_maxValue(this); }
  static num _get_maxValue(var _this) native;

  num get minValue() { return _get_minValue(this); }
  static num _get_minValue(var _this) native;

  String get name() { return _get_name(this); }
  static String _get_name(var _this) native;

  int get units() { return _get_units(this); }
  static int _get_units(var _this) native;

  num get value() { return _get_value(this); }
  static num _get_value(var _this) native;

  void set value(num value) { _set_value(this, value); }
  static void _set_value(var _this, num value) native;

  void cancelScheduledValues(num startTime) {
    _cancelScheduledValues(this, startTime);
    return;
  }
  static void _cancelScheduledValues(receiver, startTime) native;

  void exponentialRampToValueAtTime(num value, num time) {
    _exponentialRampToValueAtTime(this, value, time);
    return;
  }
  static void _exponentialRampToValueAtTime(receiver, value, time) native;

  void linearRampToValueAtTime(num value, num time) {
    _linearRampToValueAtTime(this, value, time);
    return;
  }
  static void _linearRampToValueAtTime(receiver, value, time) native;

  void setTargetValueAtTime(num targetValue, num time, num timeConstant) {
    _setTargetValueAtTime(this, targetValue, time, timeConstant);
    return;
  }
  static void _setTargetValueAtTime(receiver, targetValue, time, timeConstant) native;

  void setValueAtTime(num value, num time) {
    _setValueAtTime(this, value, time);
    return;
  }
  static void _setValueAtTime(receiver, value, time) native;

  void setValueCurveAtTime(Float32Array values, num time, num duration) {
    _setValueCurveAtTime(this, values, time, duration);
    return;
  }
  static void _setValueCurveAtTime(receiver, values, time, duration) native;

  String get typeName() { return "AudioParam"; }
}
