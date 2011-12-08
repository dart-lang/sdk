// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface RealtimeAnalyserNode extends AudioNode {

  int get fftSize();

  void set fftSize(int value);

  int get frequencyBinCount();

  num get maxDecibels();

  void set maxDecibels(num value);

  num get minDecibels();

  void set minDecibels(num value);

  num get smoothingTimeConstant();

  void set smoothingTimeConstant(num value);

  void getByteFrequencyData(Uint8Array array);

  void getByteTimeDomainData(Uint8Array array);

  void getFloatFrequencyData(Float32Array array);
}
