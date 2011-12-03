// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// WARNING: Do not edit - generated code.

interface AudioListener {

  num get dopplerFactor();

  void set dopplerFactor(num value);

  num get speedOfSound();

  void set speedOfSound(num value);

  void setOrientation(num x, num y, num z, num xUp, num yUp, num zUp);

  void setPosition(num x, num y, num z);

  void setVelocity(num x, num y, num z);
}
