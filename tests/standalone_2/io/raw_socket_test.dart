// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testArguments() {
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", 65536));
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", -1));
  Expect.throws(() => RawServerSocket.bind("127.0.0.1", 0, backlog: -1));
}

void testSimpleBind() {
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((s) {
    Expect.isTrue(s.port > 0);
    s.close();
    asyncEnd();
  });
}

void testInvalidBind() {
  // Bind to a unknown DNS name.
  asyncStart();
  RawServerSocket.bind("ko.faar.__hest__", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to an unavaliable IP-address.
  asyncStart();
  RawServerSocket.bind("8.8.8.8", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to a port already in use.
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((s) {
    RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, s.port).then((t) {
      Expect.fail("Multiple listens on same port");
    }).catchError((error) {
      Expect.isTrue(error is SocketException);
      s.close();
      asyncEnd();
    });
  });
}

void testSimpleConnect() {
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((socket) {
      socket.close();
    });
    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      server.close();
      socket.close();
      asyncEnd();
    });
  });
}

void testCloseOneEnd(String toClose) {
  asyncStart();
  Completer serverDone = new Completer();
  Completer serverEndDone = new Completer();
  Completer clientEndDone = new Completer();
  Future.wait([
    serverDone.future,
    serverEndDone.future,
    clientEndDone.future
  ]).then((_) {
    asyncEnd();
  });
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((serverConnection) {
      serverConnection.listen((event) {
        if (toClose == "server" || event == RawSocketEvent.READ_CLOSED) {
          serverConnection.shutdown(SocketDirection.SEND);
        }
      }, onDone: () {
        serverEndDone.complete(null);
      });
    }, onDone: () {
      serverDone.complete(null);
    });
    RawSocket.connect("127.0.0.1", server.port).then((clientConnection) {
      clientConnection.listen((event) {
        if (toClose == "client" || event == RawSocketEvent.READ_CLOSED) {
          clientConnection.shutdown(SocketDirection.SEND);
        }
      }, onDone: () {
        clientEndDone.complete(null);
        server.close();
      });
    });
  });
}

void testServerListenAfterConnect() {
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    Expect.isTrue(server.port > 0);
    RawSocket.connect("127.0.0.1", server.port).then((client) {
      server.listen((socket) {
        client.close();
        server.close();
        socket.close();
        asyncEnd();
      });
    });
  });
}

void testSimpleReadWrite({bool dropReads}) {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.
  asyncStart();

  const messageSize = 1000;
  int serverReadCount = 0;
  int clientReadCount = 0;

  List<int> createTestData() {
    return new List<int>.generate(messageSize, (index) => index & 0xff);
  }

  void verifyTestData(List<int> data) {
    Expect.equals(messageSize, data.length);
    List<int> expected = createTestData();
    for (int i = 0; i < messageSize; i++) {
      Expect.equals(expected[i], data[i]);
    }
  }

  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      int bytesRead = 0;
      int bytesWritten = 0;
      bool closedEventReceived = false;
      List<int> data = new List<int>(messageSize);

      client.writeEventsEnabled = false;
      client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            if (dropReads) {
              if (serverReadCount != 10) {
                serverReadCount++;
                break;
              } else {
                serverReadCount = 0;
              }
            }
            Expect.isTrue(bytesWritten == 0);
            Expect.isTrue(client.available() > 0);
            var buffer = client.read(200);
            data.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            if (bytesRead == data.length) {
              verifyTestData(data);
              client.writeEventsEnabled = true;
            }
            break;
          case RawSocketEvent.WRITE:
            Expect.isFalse(client.writeEventsEnabled);
            bytesWritten +=
                client.write(data, bytesWritten, data.length - bytesWritten);
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
          case RawSocketEvent.CLOSED:
            Expect.isFalse(closedEventReceived);
            closedEventReceived = true;
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: () => Expect.isTrue(closedEventReceived));
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      int bytesRead = 0;
      int bytesWritten = 0;
      bool closedEventReceived = false;
      List<int> data = createTestData();

      socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.isTrue(socket.available() > 0);
            if (dropReads) {
              if (clientReadCount != 10) {
                clientReadCount++;
                break;
              } else {
                clientReadCount = 0;
              }
            }
            var buffer = socket.read();
            data.setRange(bytesRead, bytesRead + buffer.length, buffer);
            bytesRead += buffer.length;
            break;
          case RawSocketEvent.WRITE:
            Expect.isTrue(bytesRead == 0);
            Expect.isFalse(socket.writeEventsEnabled);
            bytesWritten +=
                socket.write(data, bytesWritten, data.length - bytesWritten);
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
          case RawSocketEvent.CLOSED:
            Expect.isFalse(closedEventReceived);
            closedEventReceived = true;
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: () {
        Expect.isTrue(closedEventReceived);
        asyncEnd();
      });
    });
  });
}

testPauseServerSocket() {
  const int socketCount = 10;
  var acceptCount = 0;
  var resumed = false;

  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    Expect.isTrue(server.port > 0);
    var subscription = server.listen((socket) {
      socket.close();
      Expect.isTrue(resumed);
      if (++acceptCount == socketCount) {
        server.close();
        asyncEnd();
      }
    });

    // Pause the server socket subscription and resume it after having
    // connected a number client sockets. Then connect more client
    // sockets.
    subscription.pause();
    var connectCount = 0;
    for (int i = 0; i < socketCount / 2; i++) {
      RawSocket.connect("127.0.0.1", server.port).then((socket) {
        if (++connectCount == socketCount / 2) {
          subscription.resume();
          resumed = true;
          for (int i = connectCount; i < socketCount; i++) {
            RawSocket.connect("127.0.0.1", server.port).then((socket) {
              socket.close();
            });
          }
        }
        socket.close();
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

  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    Expect.isTrue(server.port > 0);
    server.listen((client) {
      bool closedEventReceived = false;
      List<int> data = new List<int>.filled(messageSize, 0);
      writeSubscription = client.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            throw "Unexpected read event";
          case RawSocketEvent.WRITE:
            if (pauseResumeCount == loopCount) return;
            Expect.isFalse(client.writeEventsEnabled);
            Expect.equals(0, bytesRead); // Checks that reader is paused.
            bytesWritten +=
                client.write(data, bytesWritten, data.length - bytesWritten);
            // Ensure all data is written. When done disable the write
            // event and resume the receiver.
            if (bytesWritten == data.length) {
              writeSubscription.pause();
              bytesWritten = 0;
              connected.future.then((_) {
                readSubscription.resume();
              });
            }
            client.writeEventsEnabled = true;
            break;
          case RawSocketEvent.READ_CLOSED:
            client.close();
            server.close();
            break;
          case RawSocketEvent.CLOSED:
            Expect.isFalse(closedEventReceived);
            closedEventReceived = true;
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: () => Expect.isTrue(closedEventReceived));
    });

    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      bool closedEventReceived = false;
      socket.writeEventsEnabled = false;
      readSubscription = socket.listen((event) {
        switch (event) {
          case RawSocketEvent.READ:
            Expect.equals(0, bytesWritten); // Checks that writer is paused.
            Expect.isTrue(socket.available() > 0);
            var buffer = socket.read();
            bytesRead += buffer.length;
            // Ensure all data is read. When done pause and resume the sender
            if (bytesRead == messageSize) {
              if (++pauseResumeCount == loopCount) {
                socket.close();
                asyncEnd();
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
            throw "Unexpected read closed event";
          case RawSocketEvent.CLOSED:
            Expect.isFalse(closedEventReceived);
            closedEventReceived = true;
            break;
          default:
            throw "Unexpected event $event";
        }
      }, onDone: () => Expect.isTrue(closedEventReceived));
      readSubscription.pause();
      connected.complete(true);
    });
  });
}

void testSocketZone() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((socket) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        socket.close();
        server.close();
      });
      RawSocket.connect("127.0.0.1", server.port).then((socket) {
        socket.listen((event) {
          if (event == RawSocketEvent.READ_CLOSED) {
            socket.close();
            asyncEnd();
          }
        });
      });
    });
  });
}

void testSocketZoneError() {
  asyncStart();
  Expect.equals(Zone.ROOT, Zone.current);
  runZoned(() {
    Expect.notEquals(Zone.ROOT, Zone.current);
    RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
      Expect.notEquals(Zone.ROOT, Zone.current);
      server.listen((socket) {
        Expect.notEquals(Zone.ROOT, Zone.current);
        var timer;
        void write() {
          socket.write(const [0]);
          timer = new Timer(const Duration(milliseconds: 5), write);
        }

        write();
        socket.listen((_) {}, onError: (error) {
          timer.cancel();
          Expect.notEquals(Zone.ROOT, Zone.current);
          socket.close();
          server.close();
          throw error;
        });
      });
      RawSocket.connect("127.0.0.1", server.port).then((socket) {
        socket.close();
      });
    });
  }, onError: (e) {
    asyncEnd();
  });
}

void testClosedError() {
  asyncStart();
  RawServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((socket) {
      socket.close();
    });
    RawSocket.connect("127.0.0.1", server.port).then((socket) {
      server.close();
      socket.close();
      Expect.throws(() => socket.remotePort, (e) => e is SocketException);
      Expect.throws(() => socket.remoteAddress, (e) => e is SocketException);
      asyncEnd();
    });
  });
}

main() {
  asyncStart();
  testArguments();
  testSimpleBind();
  testCloseOneEnd("client");
  testCloseOneEnd("server");
  testInvalidBind();
  testSimpleConnect();
  testServerListenAfterConnect();
  testSimpleReadWrite(dropReads: false);
  testSimpleReadWrite(dropReads: true);
  testPauseServerSocket();
  testPauseSocket();
  testSocketZone();
  testSocketZoneError();
  testClosedError();
  asyncEnd();
}
