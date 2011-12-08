// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioProcessingEventWrappingImplementation extends _EventWrappingImplementation implements AudioProcessingEvent {
  _AudioProcessingEventWrappingImplementation() : super() {}

  static create__AudioProcessingEventWrappingImplementation() native {
    return new _AudioProcessingEventWrappingImplementation();
  }

  AudioBuffer get inputBuffer() { return _get_inputBuffer(this); }
  static AudioBuffer _get_inputBuffer(var _this) native;

  AudioBuffer get outputBuffer() { return _get_outputBuffer(this); }
  static AudioBuffer _get_outputBuffer(var _this) native;

  String get typeName() { return "AudioProcessingEvent"; }
}
