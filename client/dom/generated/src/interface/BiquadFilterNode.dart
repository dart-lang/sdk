// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface BiquadFilterNode extends AudioNode {

  static final int ALLPASS = 7;

  static final int BANDPASS = 2;

  static final int HIGHPASS = 1;

  static final int HIGHSHELF = 4;

  static final int LOWPASS = 0;

  static final int LOWSHELF = 3;

  static final int NOTCH = 6;

  static final int PEAKING = 5;

  AudioParam get Q();

  AudioParam get frequency();

  AudioParam get gain();

  int get type();

  void set type(int value);
}
