// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioPannerNode extends AudioNode {

  static final int EQUALPOWER = 0;

  static final int HRTF = 1;

  static final int SOUNDFIELD = 2;

  final AudioGain coneGain;

  num coneInnerAngle;

  num coneOuterAngle;

  num coneOuterGain;

  final AudioGain distanceGain;

  int distanceModel;

  num maxDistance;

  int panningModel;

  num refDistance;

  num rolloffFactor;

  void setOrientation(num x, num y, num z);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
