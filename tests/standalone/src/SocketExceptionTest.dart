// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

class SocketExceptionTest {

  static final PORT = 0;
  static final HOST = "127.0.0.1";

  static void serverSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    server.close();
    try {
      server.close();
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(false, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      server.accept();
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
  }

  static void clientSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    int port = server.port;
    Socket client = new Socket(HOST, port);
    Expect.equals(true, client !== null);
    InputStream input = client.inputStream;
    OutputStream output = client.outputStream;
    client.close();
    try {
      client.close();
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(false, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      client.available();
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      client.readList(buffer, 0 , 10);
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(10);
      client.writeList(buffer, 0, 10);
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(42);
      bool readDone = input.readInto(buffer, 0, 12);
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;
    try {
      List<int> buffer = new List<int>(42);
      output.writeFrom(buffer, 0, 12);
    } catch (SocketIOException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);

    server.close();
  }

  static void indexOutOfRangeExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    int port = server.port;
    Socket client = new Socket(HOST, port);
    Expect.equals(true, client !== null);
    try {
      List<int> buffer = new List<int>(10);
      client.readList(buffer, -1, 1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;

    try {
      List<int> buffer = new List<int>(10);
      client.readList(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;

    try {
      List<int> buffer = new List<int>(10);
      client.writeList(buffer, -1, 1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
    exceptionCaught = false;

    try {
      List<int> buffer = new List<int>(10);
      client.writeList(buffer, 0, -1);
    } catch (IndexOutOfRangeException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);

    server.close();
    client.close();
  }

  static void testMain() {
    serverSocketExceptionTest();
    clientSocketExceptionTest();
    indexOutOfRangeExceptionTest();
  }
}

main() {
  SocketExceptionTest.testMain();
}
