// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _LowPass2FilterNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements LowPass2FilterNode {
  _LowPass2FilterNodeWrappingImplementation() : super() {}

  static create__LowPass2FilterNodeWrappingImplementation() native {
    return new _LowPass2FilterNodeWrappingImplementation();
  }

  AudioParam get cutoff() { return _get_cutoff(this); }
  static AudioParam _get_cutoff(var _this) native;

  AudioParam get resonance() { return _get_resonance(this); }
  static AudioParam _get_resonance(var _this) native;

  String get typeName() { return "LowPass2FilterNode"; }
}
