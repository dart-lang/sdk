// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioProcessingEventWrappingImplementation extends EventWrappingImplementation implements AudioProcessingEvent {
  AudioProcessingEventWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioBuffer get inputBuffer() { return LevelDom.wrapAudioBuffer(_ptr.inputBuffer); }

  AudioBuffer get outputBuffer() { return LevelDom.wrapAudioBuffer(_ptr.outputBuffer); }
}
