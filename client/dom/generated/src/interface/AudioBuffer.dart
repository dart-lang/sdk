// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioBuffer {

  final num duration;

  num gain;

  final int length;

  final int numberOfChannels;

  final num sampleRate;

  Float32Array getChannelData(int channelIndex);
}
