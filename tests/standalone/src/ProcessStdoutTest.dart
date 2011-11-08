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

#source("ProcessTestUtil.dart");

class ProcessStdoutTest {

  static void testExit() {
    Process process = new Process(getProcessTestFileName(),
                                  const ["0", "1", "99", "0"]);
    final int BUFFERSIZE = 10;
    final int STARTCHAR = 65;
    List<int> data = new List<int>(BUFFERSIZE);
    for (int i = 0; (i < BUFFERSIZE - 1); i++) {
      data[i] = STARTCHAR + i;
    }
    data[BUFFERSIZE - 1] = 10;

    InputStream input = process.stdout;
    OutputStream output = process.stdin;

    process.start();

    int received = 0;
    List<int> buffer = [];

    void readData() {
      buffer.addAll(input.read());
      for (int i = received; i < Math.min(data.length, buffer.length) - 1; i++) {
        Expect.equals(data[i], buffer[i]);
      }
      received = buffer.length;
      if (received >= BUFFERSIZE) {
        // We expect an extra character on windows due to carriage return.
        if (13 === buffer[BUFFERSIZE - 1] && BUFFERSIZE + 1 === received) {
          Expect.equals(13, buffer[BUFFERSIZE - 1]);
          Expect.equals(10, buffer[BUFFERSIZE]);
          buffer.removeLast();
          process.close();
        } else if (received === BUFFERSIZE) {
          process.close();
        }
      }
    }

    void streamClosed() {
      Expect.equals(BUFFERSIZE, received);
    }

    output.write(data);
    output.close();
    input.dataHandler = readData;
    input.closeHandler = streamClosed;
  }

  static void testMain() {
    testExit();
  }
}

main() {
  ProcessStdoutTest.testMain();
}
