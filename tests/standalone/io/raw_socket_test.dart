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
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", 65536));
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", -1));
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", 0, -1));
}

void testSimpleBind() {
  ReceivePort port = new ReceivePort();
  RawServerSocket.bind().then((s) {
    Expect.isTrue(s.port > 0);
    port.close();
  });
}

void testInvalidBind() {
  int count = 0;
  ReceivePort port = new ReceivePort();
  port.receive((_, __) { count++; if (count == 3) port.close(); });

  // Bind to a unknown DNS name.
  RawServerSocket.bind("ko.faar.__hest__")
      .then((_) { Expect.fail("Failure expected"); } )
      .catchError((error) {
        Expect.isTrue(error is SocketIOException);
        port.toSendPort().send(1);
      });

  // Bind to an unavaliable IP-address.
  RawServerSocket.bind("8.8.8.8")
      .then((_) { Expect.fail("Failure expected"); } )
      .catchError((error) {
        Expect.isTrue(error is SocketIOException);
        port.toSendPort().send(1);
      });

  // Bind to a port already in use.
  // Either an error or a successful bind is allowed.
  // Windows platforms allow multiple binding to the same socket, with
  // unpredictable results.
  RawServerSocket.bind("127.0.0.1")
      .then((s) {
        RawServerSocket.bind("127.0.0.1", s.port)
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

void testSimpleConnect() {
  ReceivePort port = new ReceivePort();
  RawServerSocket.bind().then((server) {
    server.listen((_) { });
    RawSocket.connect("127.0.0.1", server.port).then((_) {
      server.close();
      port.close();
    });
  });
}

void testCloseOneEnd(String toClose) {
  ReceivePort port = new ReceivePort();
  Completer serverDone = new Completer();
  Completer serverEndDone = new Completer();
  Completer clientEndDone = new Completer();
  Future.wait([serverDone.future, serverEndDone.future, clientEndDone.future])
      .then((_) {
        port.close();
      });
  RawServerSocket.bind().then((server) {
    server.listen((serverConnection) {
      serverConnection.listen((event) {
        if (toClose == "server" || event == RawSocketEvent.READ_CLOSED) {
          serverConnection.shutdown(SocketDirection.SEND);
        }
      },
      onDone: () {
        serverEndDone.complete(null);
      });
    },
    onDone:() {
      serverDone.complete(null);
    });
    RawSocket.connect("127.0.0.1", server.port).then((clientConnection) {
      clientConnection.listen((event){
        if (toClose == "client" || event == RawSocketEvent.READ_CLOSED) {
          clientConnection.shutdown(SocketDirection.SEND);
        }
      },
      onDone: () {
        clientEndDone.complete(null);
        server.close();
      });
    });
  });
}

void testServerListenAfterConnect() {
  ReceivePort port = new ReceivePort();
  RawServerSocket.bind().then((server) {
    Expect.isTrue(server.port > 0);
    RawSocket.connect("127.0.0.1", server.port).then((_) {
      server.listen((_) {
        server.close();
        port.close();
      });
    });
  });
}

void testSimpleReadWrite() {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.
  ReceivePort port = new ReceivePort();

  const messageSize = 1000;

  List<int> createTestData() {
    List<int> data = new List<int>(messageSize);
    for (int i = 0; i < messageSize; i++) {
      data[i] = i & 0xff;
    }
    return data;
  }

  void verifyTestData(List<int> data) {
    Expect.equals(messageSize, data.length);
    List<int> expected = createTestData();
    for (int i = 0; i < messageSize; i++) {
      Expect.equals(expected[i], data[i]);
    }
  }

  RawServerSocket.bind().then((server) {
    server.listen((client) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> data = new List<int>(messageSize);

      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(bytesWritten == 0);
            Expect.isTrue(client.available() > 0);
            var buffer = client.read();
            data.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            if (bytesRead == data.length) {
              verifyTestData(data);
              client.writeEventsEnabled = true;
            }
            break;
          case RawSocketEvent.WRITE:
            Expect.isFalse(client.writeEventsEnabled);
            bytesWritten += client.write(
                data, bytesWritten, data.length - bytesWritten);
            if (bytesWritten < data.length) {
              client.writeEventsEnabled = true;
            }
            if (bytesWritten == data.length) {
              client.shutdown(SocketDirection.SEND);
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            server.close();
            break;
          default: throw "Unexpected event $event";
        }
      });
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> data = createTestData();

      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(socket.available() > 0);
            var buffer = socket.read();
            data.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            break;
          case RawSocketEvent.WRITE:
            Expect.isTrue(bytesRead == 0);
            Expect.isFalse(socket.writeEventsEnabled);
            bytesWritten += socket.write(
                data, bytesWritten, data.length - bytesWritten);
            if (bytesWritten < data.length) {
              socket.writeEventsEnabled = true;
            } else {
              data = new List<int>(messageSize);
            }
            break;
          case RawSocketEvent.READ_CLOSED:
            verifyTestData(data);
            socket.close();
            break;
          default: throw "Unexpected event $event";
        }
      },
      onDone: () => port.close());
    });
  });
}

testPauseServerSocket() {
  const int socketCount = 10;
  var acceptCount = 0;
  var resumed = false;

  ReceivePort port = new ReceivePort();

  RawServerSocket.bind().then((server) {
    Expect.isTrue(server.port > 0);
    var subscription = server.listen((_) {
      Expect.isTrue(resumed);
      if (++acceptCount == socketCount) {
        server.close();
        port.close();
      }
    });

    // Pause the server socket subscription and resume it after having
    // connected a number client sockets. Then connect more client
    // sockets.
    subscription.pause();
    var connectCount = 0;
    for (int i = 0; i <= socketCount / 2; i++) {
      RawSocket.connect("127.0.0.1", server.port).then((_) {
        if (++connectCount == socketCount / 2) {
          subscription.resume();
          resumed = true;
          for (int i = connectCount; i < socketCount; i++) {
            RawSocket.connect("127.0.0.1", server.port).then((_) {});
          }
        }
      });
    }
  });
}

void testPauseSocket() {
  const messageSize = 1000;
  const loopCount = 10;
  Completer connected = new Completer();
  int pauseResumeCount = 0;
  int bytesWritten = 0;
  int bytesRead = 0;
  var writeSubscription;
  var readSubscription;

  ReceivePort port = new ReceivePort();

  RawServerSocket.bind().then((server) {
    Expect.isTrue(server.port > 0);
    server.listen((client) {
      List<int> data = new List<int>.filled(messageSize, 0);
      writeSubscription = client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            throw "Unexpected read event";
          case RawSocketEvent.WRITE:
            if (pauseResumeCount == loopCount) return;
            Expect.isFalse(client.writeEventsEnabled);
            Expect.equals(0, bytesRead);  // Checks that reader is paused.
            bytesWritten += client.write(
                data, bytesWritten, data.length - bytesWritten);
            // Ensure all data is written. When done disable the write
            // event and resume the receiver.
            if (bytesWritten == data.length) {
              writeSubscription.pause();
              bytesWritten = 0;
              connected.future.then((_) { readSubscription.resume(); });
            }
            client.writeEventsEnabled = true;
            break;
          case RawSocketEvent.READ_CLOSED:
            client.close();
            server.close();
            break;
          default: throw "Unexpected event $event";
        }
      });
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      socket.writeEventsEnabled = false;
      readSubscription = socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.equals(0, bytesWritten);  // Checks that writer is paused.
            Expect.isTrue(socket.available() > 0);
            var buffer = socket.read();
            bytesRead += buffer.length;
            // Ensure all data is read. When done pause and resume the sender
            if (bytesRead == messageSize) {
              if (++pauseResumeCount == loopCount) {
                socket.close();
                port.close();
              } else {
                readSubscription.pause();
              }
              // Always resume writer as it needs the read closed
              // event when done.
              bytesRead = 0;
              writeSubscription.resume();
            }
            break;
          case RawSocketEvent.WRITE:
            throw "Unexpected write event";
          case RawSocketEvent.READ_CLOSED:
            throw "Unexpected close event";
          default: throw "Unexpected event $event";
        }
      });
      readSubscription.pause();
      connected.complete(true);
    });
  });
}

main() {
  testArguments();
  testSimpleBind();
  testCloseOneEnd("client");
  testCloseOneEnd("server");
  testInvalidBind();
  testSimpleConnect();
  testServerListenAfterConnect();
  testSimpleReadWrite();
  testPauseServerSocket();
  testPauseSocket();
}
