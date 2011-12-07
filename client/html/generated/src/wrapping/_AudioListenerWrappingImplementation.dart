// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

class AudioListenerWrappingImplementation extends DOMWrapperBase implements AudioListener {
  AudioListenerWrappingImplementation._wrap(ptr) : super._wrap(ptr) {}

  num get dopplerFactor() { return _ptr.dopplerFactor; }

  void set dopplerFactor(num value) { _ptr.dopplerFactor = value; }

  num get speedOfSound() { return _ptr.speedOfSound; }

  void set speedOfSound(num value) { _ptr.speedOfSound = value; }

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp) {
    _ptr.setOrientation(x, y, z, xUp, yUp, zUp);
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
