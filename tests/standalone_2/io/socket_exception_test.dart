// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Tests socket exceptions.

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

class SocketExceptionTest {
  static void serverSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket.bind("127.0.0.1", 0).then((server) {
      Expect.isNotNull(server);
      server.close();
      try {
        server.close();
      } on SocketException catch (ex) {
        exceptionCaught = true;
      } catch (ex) {
        wrongExceptionCaught = true;
      }
      Expect.equals(false, exceptionCaught);
      Expect.equals(true, !wrongExceptionCaught);

      // Test invalid host.
      ServerSocket
          .bind("__INVALID_HOST__", 0)
          .then((server) {})
          .catchError((e) => e is SocketException);
    });
  }

  static void serverSocketCloseListenTest() {
    asyncStart();
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        socket.destroy();
        server.close();
        server.listen((incoming) => Expect.fail("Unexpected socket"),
            onDone: asyncEnd);
      });
    });
  }

  static void serverSocketListenCloseTest() {
    asyncStart();
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      Socket.connect("127.0.0.1", server.port).then((socket) {
        server.listen((incoming) {
          incoming.destroy();
          socket.destroy();
          server.close();
        }, onDone: asyncEnd);
      });
    });
  }

  static void clientSocketExceptionTest() {
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;

    ServerSocket.bind("127.0.0.1", 0).then((server) {
      Expect.isNotNull(server);
      int port = server.port;
      Socket.connect("127.0.0.1", port).then((client) {
        Expect.isNotNull(client);
        client.close();
        // First calls for which exceptions are note expected.
        try {
          client.close();
        } on SocketException catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isFalse(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        try {
          client.destroy();
        } on SocketException catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
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
        Expect.isFalse(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);

        // From here exceptions are expected.
        exceptionCaught = false;
        try {
          client.port;
        } on SocketException catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isTrue(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        exceptionCaught = false;
        try {
          client.remotePort;
        } on SocketException catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isTrue(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        exceptionCaught = false;
        try {
          client.address;
        } on SocketException catch (ex) {
          exceptionCaught = true;
        } catch (ex) {
          wrongExceptionCaught = true;
        }
        Expect.isTrue(exceptionCaught);
        Expect.isFalse(wrongExceptionCaught);
        exceptionCaught = false;
        try {
          client.remoteAddress;
        } on SocketException catch (ex) {
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
    ServerSocket.bind("127.0.0.1", 0).then((server) {
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
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      server.listen((socket) {
        // Passive block data by not subscribing to socket.
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        client.listen((data) {}, onDone: server.close);
        client.add(new List.filled(1024 * 1024, 0));
        client.destroy();
      });
    });
  }

  static void clientSocketAddCloseNoErrorTest() {
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      var completer = new Completer();
      server.listen((socket) {
        // The socket is 'paused' until the future completes.
        completer.future.then((_) => socket.pipe(socket));
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int count = 0;
        client.listen((data) => count += data.length, onDone: () {
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
    asyncStart();
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      var completer = new Completer();
      server.listen((socket) {
        completer.future.then((_) => socket.destroy());
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int errors = 0;
        client.listen((data) => Expect.fail("Unexpected data"),
            onError: (error) {
          Expect.isTrue(error is SocketException);
          errors++;
        }, onDone: () {
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
        client.done.then((_) {
          Expect.fail("Expected error");
        }, onError: (error) {
          Expect.isTrue(error is SocketException);
          asyncEnd();
        });
      });
    });
  }

  static void clientSocketAddCloseResultErrorTest() {
    ServerSocket.bind("127.0.0.1", 0).then((server) {
      var completer = new Completer();
      server.listen((socket) {
        completer.future.then((_) => socket.destroy());
      });
      Socket.connect("127.0.0.1", server.port).then((client) {
        const int SIZE = 1024 * 1024;
        int errors = 0;
        client.add(new List.filled(SIZE, 0));
        client.close();
        client.done.catchError((_) {}).whenComplete(() {
          server.close();
        });
        // Destroy other socket now.
        completer.complete(null);
      });
    });
  }

  static void unknownHostTest() {
    asyncStart();
    Socket
        .connect("hede.hule.hest", 1234)
        .then((socket) => Expect.fail("Connection completed"))
        .catchError((e) => asyncEnd(), test: (e) => e is SocketException);
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
  asyncStart();
  SocketExceptionTest.testMain();
  asyncEnd();
}
