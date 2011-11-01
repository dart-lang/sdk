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

  static void testStdout() {
    Process process = new Process("out/Debug_ia32//process_test",
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

    void readData() {
      List<int> buffer = input.read();
      for (int i = 0; i < buffer.length; i++) {
        Expect.equals(data[received + i], buffer[i]);
      }
      received += buffer.length;
      if (received == BUFFERSIZE) {
        process.close();
      }
    }

    void streamClosed() {
      Expect.equals(BUFFERSIZE, received);
    }

    output.write(data);
    output.end();
    input.dataHandler = readData;
    input.closeHandler = streamClosed;
  }

  static void testMain() {
    testStdout();
  }
}

main() {
  ProcessStdoutTest.testMain();
}
