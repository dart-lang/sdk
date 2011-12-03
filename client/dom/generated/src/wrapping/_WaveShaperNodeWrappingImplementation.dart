// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _WaveShaperNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements WaveShaperNode {
  _WaveShaperNodeWrappingImplementation() : super() {}

  static create__WaveShaperNodeWrappingImplementation() native {
    return new _WaveShaperNodeWrappingImplementation();
  }

  Float32Array get curve() { return _get_curve(this); }
  static Float32Array _get_curve(var _this) native;

  void set curve(Float32Array value) { _set_curve(this, value); }
  static void _set_curve(var _this, Float32Array value) native;

  String get typeName() { return "WaveShaperNode"; }
}
