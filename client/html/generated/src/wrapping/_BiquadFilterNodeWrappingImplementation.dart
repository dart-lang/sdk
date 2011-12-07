// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class BiquadFilterNodeWrappingImplementation extends AudioNodeWrappingImplementation implements BiquadFilterNode {
  BiquadFilterNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get Q() { return LevelDom.wrapAudioParam(_ptr.Q); }

  AudioParam get frequency() { return LevelDom.wrapAudioParam(_ptr.frequency); }

  AudioParam get gain() { return LevelDom.wrapAudioParam(_ptr.gain); }

  int get type() { return _ptr.type; }

  void set type(int value) { _ptr.type = value; }
}
