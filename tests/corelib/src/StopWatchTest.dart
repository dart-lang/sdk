// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test program for testing stopwatch support.

class StopWatchTest {
  static bool checkTicking(StopWatch sw) {
    sw.start();
    for (int i = 0; i < 10000; i++) {
      Math.parseInt(i.toString());
      if (sw.elapsed() > 0) {
        break;
      }
    }
    return sw.elapsed() > 0;
  }

  static bool checkStopping(StopWatch sw) {
    sw.stop();
    int v1 = sw.elapsed();
    Expect.isTrue(v1 > 0);  // Expect a non-zero elapsed time.
    StopWatch sw2 = new StopWatch();  // Used for verification.
    sw2.start();
    for (int i = 0; i < 10000; i++) {
      Math.parseInt(i.toString());
      int v2 = sw.elapsed();
      if (v1 != v2) {
        return false;
      }
      v1 = v2;
    }
    // The test only makes sense if measureable time elapsed and elapsed time
    // on the stopped StopWatch did not increase.
    Expect.isTrue(sw2.elapsed() > 0);
    return true;
  }

  static checkRestart() {
    StopWatch sw = new StopWatch();
    sw.start();
    for (int i = 0; i < 1000; i++) {
      Math.parseInt(i.toString());
    }
    sw.stop();
    int initial = sw.elapsed();
    sw.start();
    for (int i = 0; i < 10; i++) {
      Math.parseInt(i.toString());
    }
    sw.stop();
    Expect.isTrue(sw.elapsed() >= initial);
  }

  static testMain() {
    StopWatch sw = new StopWatch();
    Expect.isTrue(checkTicking(sw));
    Expect.isTrue(checkStopping(sw));
    checkRestart();
  }
}

main() {
  StopWatchTest.testMain();
}
