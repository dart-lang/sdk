// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBufferSourceNode extends AudioSourceNode {

  AudioBuffer buffer;

  final AudioGain gain;

  bool loop;

  bool looping;

  final AudioParam playbackRate;

  void noteGrainOn(num when, num grainOffset, num grainDuration);

  void noteOff(num when);

  void noteOn(num when);
}
