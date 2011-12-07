// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioBufferWrappingImplementation extends DOMWrapperBase implements AudioBuffer {
  AudioBufferWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get duration() { return _ptr.duration; }

  num get gain() { return _ptr.gain; }

  void set gain(num value) { _ptr.gain = value; }

  int get length() { return _ptr.length; }

  int get numberOfChannels() { return _ptr.numberOfChannels; }

  num get sampleRate() { return _ptr.sampleRate; }

  Float32Array getChannelData(int channelIndex) {
    return LevelDom.wrapFloat32Array(_ptr.getChannelData(channelIndex));
  }
}
