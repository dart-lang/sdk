// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBufferSourceNode extends AudioSourceNode {

  AudioBuffer get buffer();

  void set buffer(AudioBuffer value);

  AudioGain get gain();

  bool get loop();

  void set loop(bool value);

  bool get looping();

  void set looping(bool value);

  AudioParam get playbackRate();

  void noteGrainOn(num when, num grainOffset, num grainDuration);

  void noteOff(num when);

  void noteOn(num when);
}
