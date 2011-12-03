// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioPannerNodeWrappingImplementation extends _AudioNodeWrappingImplementation implements AudioPannerNode {
  _AudioPannerNodeWrappingImplementation() : super() {}

  static create__AudioPannerNodeWrappingImplementation() native {
    return new _AudioPannerNodeWrappingImplementation();
  }

  AudioGain get coneGain() { return _get_coneGain(this); }
  static AudioGain _get_coneGain(var _this) native;

  num get coneInnerAngle() { return _get_coneInnerAngle(this); }
  static num _get_coneInnerAngle(var _this) native;

  void set coneInnerAngle(num value) { _set_coneInnerAngle(this, value); }
  static void _set_coneInnerAngle(var _this, num value) native;

  num get coneOuterAngle() { return _get_coneOuterAngle(this); }
  static num _get_coneOuterAngle(var _this) native;

  void set coneOuterAngle(num value) { _set_coneOuterAngle(this, value); }
  static void _set_coneOuterAngle(var _this, num value) native;

  num get coneOuterGain() { return _get_coneOuterGain(this); }
  static num _get_coneOuterGain(var _this) native;

  void set coneOuterGain(num value) { _set_coneOuterGain(this, value); }
  static void _set_coneOuterGain(var _this, num value) native;

  AudioGain get distanceGain() { return _get_distanceGain(this); }
  static AudioGain _get_distanceGain(var _this) native;

  int get distanceModel() { return _get_distanceModel(this); }
  static int _get_distanceModel(var _this) native;

  void set distanceModel(int value) { _set_distanceModel(this, value); }
  static void _set_distanceModel(var _this, int value) native;

  num get maxDistance() { return _get_maxDistance(this); }
  static num _get_maxDistance(var _this) native;

  void set maxDistance(num value) { _set_maxDistance(this, value); }
  static void _set_maxDistance(var _this, num value) native;

  int get panningModel() { return _get_panningModel(this); }
  static int _get_panningModel(var _this) native;

  void set panningModel(int value) { _set_panningModel(this, value); }
  static void _set_panningModel(var _this, int value) native;

  num get refDistance() { return _get_refDistance(this); }
  static num _get_refDistance(var _this) native;

  void set refDistance(num value) { _set_refDistance(this, value); }
  static void _set_refDistance(var _this, num value) native;

  num get rolloffFactor() { return _get_rolloffFactor(this); }
  static num _get_rolloffFactor(var _this) native;

  void set rolloffFactor(num value) { _set_rolloffFactor(this, value); }
  static void _set_rolloffFactor(var _this, num value) native;

  void setOrientation(num x, num y, num z) {
    _setOrientation(this, x, y, z);
    return;
  }
  static void _setOrientation(receiver, x, y, z) native;

  void setPosition(num x, num y, num z) {
    _setPosition(this, x, y, z);
    return;
  }
  static void _setPosition(receiver, x, y, z) native;

  void setVelocity(num x, num y, num z) {
    _setVelocity(this, x, y, z);
    return;
  }
  static void _setVelocity(receiver, x, y, z) native;

  String get typeName() { return "AudioPannerNode"; }
}
