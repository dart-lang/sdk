// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class RealtimeAnalyserNodeWrappingImplementation extends AudioNodeWrappingImplementation implements RealtimeAnalyserNode {
  RealtimeAnalyserNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  int get fftSize() { return _ptr.fftSize; }

  void set fftSize(int value) { _ptr.fftSize = value; }

  int get frequencyBinCount() { return _ptr.frequencyBinCount; }

  num get maxDecibels() { return _ptr.maxDecibels; }

  void set maxDecibels(num value) { _ptr.maxDecibels = value; }

  num get minDecibels() { return _ptr.minDecibels; }

  void set minDecibels(num value) { _ptr.minDecibels = value; }

  num get smoothingTimeConstant() { return _ptr.smoothingTimeConstant; }

  void set smoothingTimeConstant(num value) { _ptr.smoothingTimeConstant = value; }

  void getByteFrequencyData(Uint8Array array) {
    _ptr.getByteFrequencyData(LevelDom.unwrap(array));
    return;
  }

  void getByteTimeDomainData(Uint8Array array) {
    _ptr.getByteTimeDomainData(LevelDom.unwrap(array));
    return;
  }

  void getFloatFrequencyData(Float32Array array) {
    _ptr.getFloatFrequencyData(LevelDom.unwrap(array));
    return;
  }
}
