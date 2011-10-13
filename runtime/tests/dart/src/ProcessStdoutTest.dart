// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Process test program to test process communication.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

class ProcessStdoutTest {

  static void testExit() {
    Process process = new Process("out/Debug_ia32//process_test",
                                   const ["0", "1", "99", "0"]);
    final int BUFFERSIZE = 10;
    final int STARTCHAR = 65;
    List<int> buffer = new List<int>(BUFFERSIZE);
    for (int i = 0; (i < BUFFERSIZE - 1); i++) {
      buffer[i] = STARTCHAR + i;
    }
    buffer[BUFFERSIZE - 1] = 10;

    SocketInputStream input = process.stdoutStream;
    SocketOutputStream output = process.stdinStream;

    process.start();

    List<int> readBuffer = new List<int>(BUFFERSIZE);

    void dataWritten() {
      void readData() {
        for (int i = 0; i < BUFFERSIZE; i++) {
          Expect.equals(buffer[i], readBuffer[i]);
        }
        process.close();
      }

      bool read = input.read(readBuffer, 0, BUFFERSIZE, readData);
      if (read) {
        readData();
      }
    }
    bool written = output.write(buffer, 0, BUFFERSIZE, dataWritten);
    if (written) {
      dataWritten();
    }
  }

  static void testMain() {
    testExit();
  }
}

main() {
  ProcessStdoutTest.testMain();
}
