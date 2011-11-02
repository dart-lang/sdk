// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

class ProcessExitTest {

  static void testExit() {
    Process process = new Process("out/Debug_ia32/process_test",
                                  const ["0", "0", "99", "0"]);

    void exitHandler(int exitCode) {
      Expect.equals(exitCode, 99);
      process.close();
    }

    process.exitHandler = exitHandler;
    process.start();
  }

  static void testMain() {
    testExit();
  }
}

main() {
  ProcessExitTest.testMain();
}
