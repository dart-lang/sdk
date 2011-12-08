// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioBufferWrappingImplementation extends DOMWrapperBase implements AudioBuffer {
  _AudioBufferWrappingImplementation() : super() {}

  static create__AudioBufferWrappingImplementation() native {
    return new _AudioBufferWrappingImplementation();
  }

  num get duration() { return _get_duration(this); }
  static num _get_duration(var _this) native;

  num get gain() { return _get_gain(this); }
  static num _get_gain(var _this) native;

  void set gain(num value) { _set_gain(this, value); }
  static void _set_gain(var _this, num value) native;

  int get length() { return _get_length(this); }
  static int _get_length(var _this) native;

  int get numberOfChannels() { return _get_numberOfChannels(this); }
  static int _get_numberOfChannels(var _this) native;

  num get sampleRate() { return _get_sampleRate(this); }
  static num _get_sampleRate(var _this) native;

  Float32Array getChannelData(int channelIndex) {
    return _getChannelData(this, channelIndex);
  }
  static Float32Array _getChannelData(receiver, channelIndex) native;

  String get typeName() { return "AudioBuffer"; }
}
