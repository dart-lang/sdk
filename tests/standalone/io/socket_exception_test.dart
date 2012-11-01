// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

#import("dart:isolate");
#import("dart:io");

class SocketExceptionTest {

  static const PORT = 0;
  static const HOST = "127.0.0.1";

  static void serverSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    server.close();
    try {
      server.close();
    } on SocketIOException catch(ex) {
      exceptionCaught = true;
    } on Exception catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(false, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);

    // Test invalid host.
    Expect.throws(() => new ServerSocket("__INVALID_HOST__", PORT, 10),
                  (e) => e is SocketIOException);
  }

  static void clientSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    int port = server.port;
    Socket client = new Socket(HOST, port);
    client.onConnect = () {
      Expect.equals(true, client !== null);
      InputStream input = client.inputStream;
      OutputStream output = client.outputStream;
      client.close();
      try {
        client.close();
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(false, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;
      try {
        client.available();
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;
      try {
        List<int> buffer = new List<int>(10);
        client.readList(buffer, 0 , 10);
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;
      try {
        List<int> buffer = new List<int>(10);
        client.writeList(buffer, 0, 10);
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;
      try {
        List<int> buffer = new List<int>(42);
        input.readInto(buffer, 0, 12);
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;
      try {
        List<int> buffer = new List<int>(42);
        output.writeFrom(buffer, 0, 12);
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);

      server.close();
    };
  }

  static void indexOutOfRangeExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket server = new ServerSocket(HOST, PORT, 10);
    Expect.equals(true, server !== null);
    int port = server.port;
    Socket client = new Socket(HOST, port);
    client.onConnect = () {
      Expect.equals(true, client !== null);
      try {
        List<int> buffer = new List<int>(10);
        client.readList(buffer, -1, 1);
      } on RangeError catch (ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;

      try {
        List<int> buffer = new List<int>(10);
        client.readList(buffer, 0, -1);
      } on RangeError catch (ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;

      try {
        List<int> buffer = new List<int>(10);
        client.writeList(buffer, -1, 1);
      } on RangeError catch (ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);
      exceptionCaught = false;

      try {
        List<int> buffer = new List<int>(10);
        client.writeList(buffer, 0, -1);
      } on RangeError catch (ex) {
        exceptionCaught = true;
      } on Exception catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(true, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);

      server.close();
      client.close();
    };
  }

  static void unknownHostTest() {
    // Port to verify that the test completes.
    var port = new ReceivePort();
    port.receive((message, replyTo) => null);

    Socket s =  new Socket("hede.hule.hest", 1234);
    s.onError = (e) => port.close();
    s.onConnect = () => Expect.fail("Connection completed");
  }

  static void testMain() {
    serverSocketExceptionTest();
    clientSocketExceptionTest();
    indexOutOfRangeExceptionTest();
    unknownHostTest();
  }
}

main() {
  SocketExceptionTest.testMain();
}

