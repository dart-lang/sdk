// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioBufferSourceNodeWrappingImplementation extends _AudioSourceNodeWrappingImplementation implements AudioBufferSourceNode {
  _AudioBufferSourceNodeWrappingImplementation() : super() {}

  static create__AudioBufferSourceNodeWrappingImplementation() native {
    return new _AudioBufferSourceNodeWrappingImplementation();
  }

  AudioBuffer get buffer() { return _get_buffer(this); }
  static AudioBuffer _get_buffer(var _this) native;

  void set buffer(AudioBuffer value) { _set_buffer(this, value); }
  static void _set_buffer(var _this, AudioBuffer value) native;

  AudioGain get gain() { return _get_gain(this); }
  static AudioGain _get_gain(var _this) native;

  bool get loop() { return _get_loop(this); }
  static bool _get_loop(var _this) native;

  void set loop(bool value) { _set_loop(this, value); }
  static void _set_loop(var _this, bool value) native;

  bool get looping() { return _get_looping(this); }
  static bool _get_looping(var _this) native;

  void set looping(bool value) { _set_looping(this, value); }
  static void _set_looping(var _this, bool value) native;

  AudioParam get playbackRate() { return _get_playbackRate(this); }
  static AudioParam _get_playbackRate(var _this) native;

  void noteGrainOn(num when, num grainOffset, num grainDuration) {
    _noteGrainOn(this, when, grainOffset, grainDuration);
    return;
  }
  static void _noteGrainOn(receiver, when, grainOffset, grainDuration) native;

  void noteOff(num when) {
    _noteOff(this, when);
    return;
  }
  static void _noteOff(receiver, when) native;

  void noteOn(num when) {
    _noteOn(this, when);
    return;
  }
  static void _noteOn(receiver, when) native;

  String get typeName() { return "AudioBufferSourceNode"; }
}
