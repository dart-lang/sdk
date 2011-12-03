// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _RealtimeAnalyserNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements RealtimeAnalyserNode {
  _RealtimeAnalyserNodeWrappingImplementation() : super() {}

  static create__RealtimeAnalyserNodeWrappingImplementation() native {
    return new _RealtimeAnalyserNodeWrappingImplementation();
  }

  int get fftSize() { return _get_fftSize(this); }
  static int _get_fftSize(var _this) native;

  void set fftSize(int value) { _set_fftSize(this, value); }
  static void _set_fftSize(var _this, int value) native;

  int get frequencyBinCount() { return _get_frequencyBinCount(this); }
  static int _get_frequencyBinCount(var _this) native;

  num get maxDecibels() { return _get_maxDecibels(this); }
  static num _get_maxDecibels(var _this) native;

  void set maxDecibels(num value) { _set_maxDecibels(this, value); }
  static void _set_maxDecibels(var _this, num value) native;

  num get minDecibels() { return _get_minDecibels(this); }
  static num _get_minDecibels(var _this) native;

  void set minDecibels(num value) { _set_minDecibels(this, value); }
  static void _set_minDecibels(var _this, num value) native;

  num get smoothingTimeConstant() { return _get_smoothingTimeConstant(this); }
  static num _get_smoothingTimeConstant(var _this) native;

  void set smoothingTimeConstant(num value) { _set_smoothingTimeConstant(this, value); }
  static void _set_smoothingTimeConstant(var _this, num value) native;

  void getByteFrequencyData(Uint8Array array) {
    _getByteFrequencyData(this, array);
    return;
  }
  static void _getByteFrequencyData(receiver, array) native;

  void getByteTimeDomainData(Uint8Array array) {
    _getByteTimeDomainData(this, array);
    return;
  }
  static void _getByteTimeDomainData(receiver, array) native;

  void getFloatFrequencyData(Float32Array array) {
    _getFloatFrequencyData(this, array);
    return;
  }
  static void _getFloatFrequencyData(receiver, array) native;

  String get typeName() { return "RealtimeAnalyserNode"; }
}
