// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Based on dartbug.com/7681
// Verify that context chains do not lead to unintended memory being held.

library closure_cycles_test;

import "dart:async";

class X {
  Function onX;
  X() {
    Timer.run(() => onX(new Y()));
  }
}

class Y {
  Function onY;
  var heavyMemory;
  static var count = 0;
  Y() {
    // Consume large amounts of memory per iteration to fail/succeed quicker.
    heavyMemory = new List(10 * 1024 * 1024);
    // Terminate the test if we allocated enough memory without running out.
    if (count++ > 100) return;
    Timer.run(() => onY());
  }
}

void doIt() {
  var x = new X();
  x.onX = (y) {
    y.onY = () {
      y; // Capturing y can lead to endless context chains!
      doIt();
    };
  };
}

void main() {
  doIt();
}
