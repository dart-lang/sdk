// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.

class ProcessStartExceptionTest {

  static void testStartException() {
    Process process =
        new Process("__path_to_something_that_hopefully_does_not_exist__",
                    const []);

    void exitHandler(int exitCode) {
      exitHandlerCalled = false;
    }

    process.exitHandler = exitHandler;
    try {
      process.start();
    } catch (ProcessException e) {
      errorCode = e.errorCode;
    }
  }

  static void testMain() {
    exitHandlerCalled = false;
    testStartException();
    Expect.equals(2, errorCode);
    Expect.equals(false, exitHandlerCalled);
  }

  static int errorCode;
  static bool exitHandlerCalled;
}

main() {
  ProcessStartExceptionTest.testMain();
}
