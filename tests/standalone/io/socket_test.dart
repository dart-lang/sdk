// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:isolate";

void testArguments() {
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 65536));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", -1));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 0, -1));
}

void testSimpleBind() {
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((s) {
    Expect.isTrue(s.port > 0);
    port.close();
  });
}

void testInvalidBind() {
  int count = 0;
  ReceivePort port = new ReceivePort();
  port.receive((_, __) { count++; if (count == 3) port.close(); });

  // Bind to a unknown DNS name.
  ServerSocket.bind("ko.faar.__hest__")
      .then((_) { Expect.fail("Failure expected"); } )
      .catchError((error) {
        Expect.isTrue(error is SocketIOException);
        port.toSendPort().send(1);
      });

  // Bind to an unavaliable IP-address.
  ServerSocket.bind("8.8.8.8")
      .then((_) { Expect.fail("Failure expected"); } )
      .catchError((error) {
        Expect.isTrue(error is SocketIOException);
        port.toSendPort().send(1);
      });

  // Bind to a port already in use.
  // Either an error or a successful bind is allowed.
  // Windows platforms allow multiple binding to the same socket, with
  // unpredictable results.
  ServerSocket.bind("127.0.0.1")
      .then((s) {
        ServerSocket.bind("127.0.0.1", s.port)
            .then((t) {
              Expect.equals('windows', Platform.operatingSystem);
              Expect.equals(s.port, t.port);
              port.toSendPort().send(1);
            })
            .catchError((error) {
              Expect.notEquals('windows', Platform.operatingSystem);
              Expect.isTrue(error is SocketIOException);
              port.toSendPort().send(1);
            });
      });
}

void testConnectNoDestroy() {
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen((_) { });
    Socket.connect("127.0.0.1", server.port).then((_) {
      server.close();
      port.close();
    });
  });
}

void testConnectImmediateDestroy() {
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen((_) { });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.destroy();
      server.close();
      port.close();
    });
  });
}

void testConnectConsumerClose() {
  // Connect socket then immediate close the consumer without
  // listening on the stream.
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen((_) { });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.close();
      socket.done.then((_) {
        socket.destroy();
        server.close();
        port.close();
      });
    });
  });
}

void testConnectConsumerWriteClose() {
  // Connect socket write some data immediate close the consumer
  // without listening on the stream.
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen((_) { });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.add([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      socket.close();
      socket.done.then((_) {
        socket.destroy();
        server.close();
        port.close();
      });
    });
  });
}

void testConnectStreamClose() {
  // Connect socket and listen on the stream. The server closes
  // immediately so only a done event is received.
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen((client) {
                    client.close();
                    client.done.then((_) => client.destroy());
                  });
    Socket.connect("127.0.0.1", server.port).then((socket) {
        bool onDoneCalled = false;
        socket.listen((_) { Expect.fail("Unexpected data"); },
                      onDone: () {
                        Expect.isFalse(onDoneCalled);
                        onDoneCalled = true;
                        socket.close();
                        server.close();
                        port.close();
                      });
    });
  });
}

void testConnectStreamDataClose(bool useDestroy) {
  // Connect socket and listen on the stream. The server sends data
  // and then closes so both data and a done event is received.
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen(
        (client) {
          client.add(sendData);
          if (useDestroy) {
            client.destroy();
          } else {
            client.close();
          }
          client.done.then((_) { if (!useDestroy) { client.destroy(); } });
        });
    Socket.connect("127.0.0.1", server.port).then((socket) {
        List<int> data = [];
        bool onDoneCalled = false;
        socket.listen(data.addAll,
                      onDone: () {
                        Expect.isFalse(onDoneCalled);
                        onDoneCalled = true;
                        if (!useDestroy) Expect.listEquals(sendData, data);
                        socket.add([0]);
                        socket.close();
                        server.close();
                        port.close();
                      });
    });
  });
}

void testConnectStreamDataCloseCancel(bool useDestroy) {
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  ReceivePort port = new ReceivePort();
  ServerSocket.bind().then((server) {
    server.listen(
        (client) {
          client.add(sendData);
          if (useDestroy) {
            client.destroy();
          } else {
            client.close();
          }
          client.done
              .then((_) {
                if (!useDestroy) client.destroy();
              })
              .catchError((e) { /* can happen with short writes */ });
        });
    Socket.connect("127.0.0.1", server.port).then((socket) {
        List<int> data = [];
        bool onDoneCalled = false;
        var subscription;
        subscription = socket.listen(
            (_) {
              subscription.cancel();
              socket.close();
              server.close();
              port.close();
            },
            onDone: () { Expect.fail("Unexpected pipe completion"); });
    });
  });
}

main() {
  testArguments();
  testSimpleBind();
  testInvalidBind();
  testConnectNoDestroy();
  testConnectImmediateDestroy();
  testConnectConsumerClose();
  testConnectConsumerWriteClose();
  testConnectStreamClose();
  testConnectStreamDataClose(true);
  testConnectStreamDataClose(false);
  testConnectStreamDataCloseCancel(true);
  testConnectStreamDataCloseCancel(false);
}
