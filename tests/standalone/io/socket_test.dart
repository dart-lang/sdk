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
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 65536));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", -1));
  Expect.throws(() => ServerSocket.bind("127.0.0.1", 0, backlog: -1));
}

void testSimpleBind() {
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((s) {
    Expect.isTrue(s.port > 0);
    s.close();
    asyncEnd();
  });
}

void testInvalidBind() {
  // Bind to a unknown DNS name.
  asyncStart();
  ServerSocket.bind("ko.faar.__hest__", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to an unavaliable IP-address.
  asyncStart();
  ServerSocket.bind("8.8.8.8", 0).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to a port already in use.
  asyncStart();
  ServerSocket.bind("127.0.0.1", 0).then((s) {
    ServerSocket.bind("127.0.0.1", s.port).then((t) {
      Expect.fail("Multiple listens on same port");
    }).catchError((error) {
      Expect.isTrue(error is SocketException);
      s.close();
      asyncEnd();
    });
  });
}

void testConnectImmediateDestroy() {
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((_) {});
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.destroy();
      server.close();
      asyncEnd();
    });
  });
}

void testConnectConsumerClose() {
  // Connect socket then immediate close the consumer without
  // listening on the stream.
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((_) {});
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.close();
      socket.done.then((_) {
        socket.destroy();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testConnectConsumerWriteClose() {
  // Connect socket write some data immediate close the consumer
  // without listening on the stream.
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((_) {});
    Socket.connect("127.0.0.1", server.port).then((socket) {
      socket.add([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
      socket.close();
      socket.done.then((_) {
        socket.destroy();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testConnectStreamClose() {
  // Connect socket and listen on the stream. The server closes
  // immediately so only a done event is received.
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      client.close();
      client.done.then((_) => client.destroy());
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      bool onDoneCalled = false;
      socket.listen((_) {
        Expect.fail("Unexpected data");
      }, onDone: () {
        Expect.isFalse(onDoneCalled);
        onDoneCalled = true;
        socket.close();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testConnectStreamDataClose(bool useDestroy) {
  // Connect socket and listen on the stream. The server sends data
  // and then closes so both data and a done event is received.
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      client.add(sendData);
      if (useDestroy) {
        client.destroy();
      } else {
        client.close();
      }
      client.done.then((_) {
        if (!useDestroy) {
          client.destroy();
        }
      });
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      List<int> data = [];
      bool onDoneCalled = false;
      socket.listen(data.addAll, onDone: () {
        Expect.isFalse(onDoneCalled);
        onDoneCalled = true;
        if (!useDestroy) Expect.listEquals(sendData, data);
        socket.add([0]);
        socket.close();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testConnectStreamDataCloseCancel(bool useDestroy) {
  List<int> sendData = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];
  asyncStart();
  ServerSocket.bind(InternetAddress.LOOPBACK_IP_V4, 0).then((server) {
    server.listen((client) {
      client.add(sendData);
      if (useDestroy) {
        client.destroy();
      } else {
        client.close();
      }
      client.done.then((_) {
        if (!useDestroy) client.destroy();
      }).catchError((e) {/* can happen with short writes */});
    });
    Socket.connect("127.0.0.1", server.port).then((socket) {
      List<int> data = [];
      bool onDoneCalled = false;
      var subscription;
      subscription = socket.listen((_) {
        subscription.cancel();
        socket.close();
        server.close();
        asyncEnd();
      }, onDone: () {
        Expect.fail("Unexpected pipe completion");
      });
    });
  });
}

main() {
  testArguments();
  testSimpleBind();
  testInvalidBind();
  testConnectImmediateDestroy();
  testConnectConsumerClose();
  testConnectConsumerWriteClose();
  testConnectStreamClose();
  testConnectStreamDataClose(true);
  testConnectStreamDataClose(false);
  testConnectStreamDataCloseCancel(true);
  testConnectStreamDataCloseCancel(false);
}
