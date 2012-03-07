// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _DynamicsCompressorNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements DynamicsCompressorNode {
  _DynamicsCompressorNodeWrappingImplementation() : super() {}

  static create__DynamicsCompressorNodeWrappingImplementation() native {
    return new _DynamicsCompressorNodeWrappingImplementation();
  }

  AudioParam get knee() { return _get_knee(this); }
  static AudioParam _get_knee(var _this) native;

  AudioParam get ratio() { return _get_ratio(this); }
  static AudioParam _get_ratio(var _this) native;

  AudioParam get reduction() { return _get_reduction(this); }
  static AudioParam _get_reduction(var _this) native;

  AudioParam get threshold() { return _get_threshold(this); }
  static AudioParam _get_threshold(var _this) native;

  String get typeName() { return "DynamicsCompressorNode"; }
}
