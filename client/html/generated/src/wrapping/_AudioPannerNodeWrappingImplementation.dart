// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioPannerNodeWrappingImplementation extends AudioNodeWrappingImplementation implements AudioPannerNode {
  AudioPannerNodeWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  AudioGain get coneGain() { return LevelDom.wrapAudioGain(_ptr.coneGain); }

  num get coneInnerAngle() { return _ptr.coneInnerAngle; }

  void set coneInnerAngle(num value) { _ptr.coneInnerAngle = value; }

  num get coneOuterAngle() { return _ptr.coneOuterAngle; }

  void set coneOuterAngle(num value) { _ptr.coneOuterAngle = value; }

  num get coneOuterGain() { return _ptr.coneOuterGain; }

  void set coneOuterGain(num value) { _ptr.coneOuterGain = value; }

  AudioGain get distanceGain() { return LevelDom.wrapAudioGain(_ptr.distanceGain); }

  int get distanceModel() { return _ptr.distanceModel; }

  void set distanceModel(int value) { _ptr.distanceModel = value; }

  num get maxDistance() { return _ptr.maxDistance; }

  void set maxDistance(num value) { _ptr.maxDistance = value; }

  int get panningModel() { return _ptr.panningModel; }

  void set panningModel(int value) { _ptr.panningModel = value; }

  num get refDistance() { return _ptr.refDistance; }

  void set refDistance(num value) { _ptr.refDistance = value; }

  num get rolloffFactor() { return _ptr.rolloffFactor; }

  void set rolloffFactor(num value) { _ptr.rolloffFactor = value; }

  void setOrientation(num x, num y, num z) {
    _ptr.setOrientation(x, y, z);
    return;
  }

  void setPosition(num x, num y, num z) {
    _ptr.setPosition(x, y, z);
    return;
  }

  void setVelocity(num x, num y, num z) {
    _ptr.setVelocity(x, y, z);
    return;
  }
}
