// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class WaveShaperNodeWrappingImplementation extends AudioNodeWrappingImplementation implements WaveShaperNode {
  WaveShaperNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  Float32Array get curve() { return LevelDom.wrapFloat32Array(_ptr.curve); }

  void set curve(Float32Array value) { _ptr.curve = LevelDom.unwrap(value); }
}
