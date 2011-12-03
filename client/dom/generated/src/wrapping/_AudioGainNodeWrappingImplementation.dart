// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioGainNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements AudioGainNode {
  _AudioGainNodeWrappingImplementation() : super() {}

  static create__AudioGainNodeWrappingImplementation() native {
    return new _AudioGainNodeWrappingImplementation();
  }

  AudioGain get gain() { return _get_gain(this); }
  static AudioGain _get_gain(var _this) native;

  String get typeName() { return "AudioGainNode"; }
}
