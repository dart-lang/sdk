// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing stopwatch support.

library stopwatch_test;

import "package:expect/expect.dart";

class StopwatchTest {
  static bool checkTicking(Stopwatch sw) {
    Expect.isFalse(sw.isRunning);
    sw.start();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 1000000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > 0) {
        break;
      }
    }
    return sw.elapsedTicks > 0;
  }

  static bool checkStopping(Stopwatch sw) {
    sw.stop();
    Expect.isFalse(sw.isRunning);
    int v1 = sw.elapsedTicks;
    Expect.isTrue(v1 > 0); // Expect a non-zero elapsed time.
    Stopwatch sw2 = new Stopwatch(); // Used for verification.
    sw2.start();
    Expect.isTrue(sw2.isRunning);
    int sw2LastElapsed = 0;
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      int v2 = sw.elapsedTicks;
      if (v1 != v2) {
        return false;
      }
      // If sw2 elapsed twice then sw must have advanced too if it wasn't
      // stopped.
      if (sw2LastElapsed > 0 && sw2.elapsedTicks > sw2LastElapsed) {
        break;
      }
      sw2LastElapsed = sw2.elapsedTicks;
    }
    // The test only makes sense if measureable time elapsed and elapsed time
    // on the stopped Stopwatch did not increase.
    Expect.isTrue(sw2.elapsedTicks > 0);
    return true;
  }

  static checkRestart() {
    Stopwatch sw = new Stopwatch();
    Expect.isFalse(sw.isRunning);
    sw.start();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > 0) {
        break;
      }
    }
    sw.stop();
    Expect.isFalse(sw.isRunning);
    int initial = sw.elapsedTicks;
    sw.start();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > initial) {
        break;
      }
    }
    sw.stop();
    Expect.isFalse(sw.isRunning);
    Expect.isTrue(sw.elapsedTicks > initial);
  }

  static checkReset() {
    Stopwatch sw = new Stopwatch();
    Expect.isFalse(sw.isRunning);
    sw.start();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > 0) {
        break;
      }
    }
    sw.stop();
    Expect.isFalse(sw.isRunning);
    sw.reset();
    Expect.isFalse(sw.isRunning);
    Expect.equals(0, sw.elapsedTicks);
    sw.start();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > 0) {
        break;
      }
    }
    sw.reset();
    Expect.isTrue(sw.isRunning);
    for (int i = 0; i < 100000; i++) {
      int.parse(i.toString());
      if (sw.elapsedTicks > 0) {
        break;
      }
    }
    sw.stop();
    Expect.isFalse(sw.isRunning);
    Expect.isTrue(sw.elapsedTicks > 0);
  }

  static testMain() {
    Stopwatch sw = new Stopwatch();
    Expect.isTrue(checkTicking(sw));
    Expect.isTrue(checkStopping(sw));
    checkRestart();
    checkReset();
  }
}

main() {
  StopwatchTest.testMain();
}
