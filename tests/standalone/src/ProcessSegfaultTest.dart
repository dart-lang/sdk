// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

#library("ProcessSegfaultTest");
#source("ProcessTestUtil.dart");

class ProcessSegfaultTest {

  static void testExit() {
    Process process = new Process(getProcessTestFileName(),
                                  const ["0", "0", "1", "1"]);

    void exitHandler(int exitCode) {
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
  ProcessSegfaultTest.testMain();
}
