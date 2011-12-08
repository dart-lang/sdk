// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class ConvolverNodeWrappingImplementation extends AudioNodeWrappingImplementation implements ConvolverNode {
  ConvolverNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get buffer() { return LevelDom.wrapAudioBuffer(_ptr.buffer); }

  void set buffer(AudioBuffer value) { _ptr.buffer = LevelDom.unwrap(value); }
}
