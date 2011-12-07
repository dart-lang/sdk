// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class HighPass2FilterNodeWrappingImplementation extends AudioNodeWrappingImplementation implements HighPass2FilterNode {
  HighPass2FilterNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioParam get cutoff() { return LevelDom.wrapAudioParam(_ptr.cutoff); }

  AudioParam get resonance() { return LevelDom.wrapAudioParam(_ptr.resonance); }
}
