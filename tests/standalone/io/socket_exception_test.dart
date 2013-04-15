// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "package:expect/expect.dart";
import "dart:async";
import "dart:isolate";
import "dart:io";

class SocketExceptionTest {

  static void serverSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket.bind().then((server) {
      Expect.isNotNull(server);
      server.close();
      try {
        server.close();
      } on SocketIOException catch(ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(false, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);

      // Test invalid host.
      ServerSocket.bind("__INVALID_HOST__")
        .then((server) { })
        .catchError((e) => e is SocketIOException);
    });
  }

  static void serverSocketCloseListenTest() {
    var port = new ReceivePort();
    ServerSocket.bind().then((server) {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        server.close();
        server.listen(
          (incoming) => Expect.fail("Unexpected socket"),
          onDone: port.close);
      });
    });
  }

  static void serverSocketListenCloseTest() {
    var port = new ReceivePort();
    ServerSocket.bind().then((server) {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        server.listen(
          (incoming) => server.close(),
          onDone: port.close());
      });
    });
  }

  static void clientSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket.bind().then((server) {
      Expect.isNotNull(server);
     int port = server.port;
      Socket.connect("127.0.0.1", port).then((client) {
       Expect.isNotNull(client);
        client.close();
        try {
          client.close();
        } on SocketIOException catch(ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isFalse(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        try {
          client.destroy();
        } on SocketIOException catch(ex) {
          exceptionCaught = true;
        } catch (ex) {
          print(ex);
          wrongExceptionCaught = true;
        }
        Expect.isFalse(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        try {
          List<int> buffer = new List<int>(10);
          client.add(buffer);
        } on StateError catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isTrue(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);

        server.close();
      });
    });
  }

  static void clientSocketDestroyNoErrorTest() {
    ServerSocket.bind().then((server) {
      server.listen((socket) {
        socket.pipe(socket);
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        client.listen((data) {}, onDone: server.close);
        client.destroy();
      });
    });
  }

  static void clientSocketAddDestroyNoErrorTest() {
    ServerSocket.bind().then((server) {
      server.listen((socket) {
        // Passive block data by not sobscribing to socket.
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        client.listen((data) {}, onDone: server.close);
        client.add(new List.filled(1024 * 1024, 0));
        client.destroy();
      });
    });
  }

  static void clientSocketAddCloseNoErrorTest() {
    ServerSocket.bind().then((server) {
      var completer = new Completer();
      server.listen((socket) {
        // The socket is 'paused' until the future completes.
        completer.future.then((_) => socket.pipe(socket));
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int count = 0;
        client.listen(
            (data) => count += data.length,
            onDone: () {
              Expect.equals(SIZE, count);
              server.close();
            });
        client.add(new List.filled(SIZE, 0));
        client.close();
        // Start piping now.
        completer.complete(null);
      });
    });
  }

  static void clientSocketAddCloseErrorTest() {
    ServerSocket.bind().then((server) {
      var completer = new Completer();
      server.listen((socket) {
        completer.future.then((_) => socket.destroy());
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int errors = 0;
        client.listen(
            (data) => Expect.fail("Unexpected data"),
            onError: (error) {
              Expect.isTrue(error is SocketIOException);
              errors++;
            },
            onDone: () {
              // We get either a close or an error followed by a close
              // on the socket.  Whether we get both depends on
              // whether the system notices the error for the read
              // event or only for the write event.
              Expect.isTrue(errors <= 1);
              server.close();
            });
        client.add(new List.filled(SIZE, 0));
        // Destroy other socket now.
        completer.complete(null);
        var port = new ReceivePort();
        client.done.then(
            (_) {
              Expect.fail("Expected error");
            },
            onError: (error) {
              Expect.isTrue(error is SocketIOException);
              port.close();
            });
      });
    });
  }

  static void clientSocketAddCloseResultErrorTest() {
    ServerSocket.bind().then((server) {
      var completer = new Completer();
      server.listen((socket) {
        completer.future.then((_) => socket.destroy());
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int errors = 0;
        client.add(new List.filled(SIZE, 0));
        client.close();
        client.done.catchError((error) {
          server.close();
        });
        // Destroy other socket now.
        completer.complete(null);
      });
    });
  }

  static void unknownHostTest() {
    // Port to verify that the test completes.
    var port = new ReceivePort();
    port.receive((message, replyTo) => null);

    Socket.connect("hede.hule.hest", 1234)
        .then((socket) => Expect.fail("Connection completed"))
        .catchError((e) => port.close(), test: (e) => e is SocketIOException);

  }

  static void testMain() {
    serverSocketExceptionTest();
    serverSocketCloseListenTest();
    serverSocketListenCloseTest();
    clientSocketExceptionTest();
    clientSocketDestroyNoErrorTest();
    clientSocketAddDestroyNoErrorTest();
    clientSocketAddCloseNoErrorTest();
    clientSocketAddCloseErrorTest();
    clientSocketAddCloseResultErrorTest();
    unknownHostTest();
  }
}

main() {
  SocketExceptionTest.testMain();
}

