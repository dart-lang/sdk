// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioBufferSourceNodeWrappingImplementation extends AudioSourceNodeWrappingImplementation implements AudioBufferSourceNode {
  AudioBufferSourceNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get buffer() { return LevelDom.wrapAudioBuffer(_ptr.buffer); }

  void set buffer(AudioBuffer value) { _ptr.buffer = LevelDom.unwrap(value); }

  AudioGain get gain() { return LevelDom.wrapAudioGain(_ptr.gain); }

  bool get loop() { return _ptr.loop; }

  void set loop(bool value) { _ptr.loop = value; }

  bool get looping() { return _ptr.looping; }

  void set looping(bool value) { _ptr.looping = value; }

  AudioParam get playbackRate() { return LevelDom.wrapAudioParam(_ptr.playbackRate); }

  void noteGrainOn(num when, num grainOffset, num grainDuration) {
    _ptr.noteGrainOn(when, grainOffset, grainDuration);
    return;
  }

  void noteOff(num when) {
    _ptr.noteOff(when);
    return;
  }

  void noteOn(num when) {
    _ptr.noteOn(when);
    return;
  }
}
