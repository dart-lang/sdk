// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class _AudioListenerWrappingImplementation extends DOMWrapperBase implements AudioListener {
  _AudioListenerWrappingImplementation() : super() {}

  static create__AudioListenerWrappingImplementation() native {
    return new _AudioListenerWrappingImplementation();
  }

  num get dopplerFactor() { return _get_dopplerFactor(this); }
  static num _get_dopplerFactor(var _this) native;

  void set dopplerFactor(num value) { _set_dopplerFactor(this, value); }
  static void _set_dopplerFactor(var _this, num value) native;

  num get speedOfSound() { return _get_speedOfSound(this); }
  static num _get_speedOfSound(var _this) native;

  void set speedOfSound(num value) { _set_speedOfSound(this, value); }
  static void _set_speedOfSound(var _this, num value) native;

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) {
    _setOrientation(this, x, y, z, xUp, yUp, zUp);
    return;
  }
  static void _setOrientation(receiver, x, y, z, xUp, yUp, zUp) native;

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

  String get typeName() { return "AudioListener"; }
}
