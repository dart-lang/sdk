// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RealtimeAnalyserNode extends AudioNode {

  int fftSize;

  final int frequencyBinCount;

  num maxDecibels;

  num minDecibels;

  num smoothingTimeConstant;

  void getByteFrequencyData(Uint8Array array);

  void getByteTimeDomainData(Uint8Array array);

  void getFloatFrequencyData(Float32Array array);
}
