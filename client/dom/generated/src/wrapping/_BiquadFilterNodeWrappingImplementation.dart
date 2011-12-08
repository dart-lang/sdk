// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _BiquadFilterNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements BiquadFilterNode {
  _BiquadFilterNodeWrappingImplementation() : super() {}

  static create__BiquadFilterNodeWrappingImplementation() native {
    return new _BiquadFilterNodeWrappingImplementation();
  }

  AudioParam get Q() { return _get_Q(this); }
  static AudioParam _get_Q(var _this) native;

  AudioParam get frequency() { return _get_frequency(this); }
  static AudioParam _get_frequency(var _this) native;

  AudioParam get gain() { return _get_gain(this); }
  static AudioParam _get_gain(var _this) native;

  int get type() { return _get_type(this); }
  static int _get_type(var _this) native;

  void set type(int value) { _set_type(this, value); }
  static void _set_type(var _this, int value) native;

  String get typeName() { return "BiquadFilterNode"; }
}
