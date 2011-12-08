// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _ConvolverNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements ConvolverNode {
  _ConvolverNodeWrappingImplementation() : super() {}

  static create__ConvolverNodeWrappingImplementation() native {
    return new _ConvolverNodeWrappingImplementation();
  }

  AudioBuffer get buffer() { return _get_buffer(this); }
  static AudioBuffer _get_buffer(var _this) native;

  void set buffer(AudioBuffer value) { _set_buffer(this, value); }
  static void _set_buffer(var _this, AudioBuffer value) native;

  String get typeName() { return "ConvolverNode"; }
}
