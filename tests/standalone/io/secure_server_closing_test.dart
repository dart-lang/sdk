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

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";
const CERTIFICATE = "localhost_cert";

void testCloseOneEnd(String toClose) {
  ReceivePort port = new ReceivePort();
  Completer serverDone = new Completer();
  Completer serverEndDone = new Completer();
  Completer clientEndDone = new Completer();
  Future.wait([serverDone.future, serverEndDone.future, clientEndDone.future])
      .then((_) {
        port.close();
      });
  SecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
    server.listen((serverConnection) {
      serverConnection.listen(
        (data) {
          Expect.fail("No data should be received by server");
        },
        onDone: () {
          serverConnection.close();
          serverEndDone.complete(null);
          server.close();
        });
      if (toClose == "server") {
        serverConnection.close();
      }
    },
    onDone: () {
      serverDone.complete(null);
    });
    SecureSocket.connect(HOST_NAME, server.port).then((clientConnection) {
      clientConnection.listen(
        (data) {
          Expect.fail("No data should be received by client");
        },
        onDone: () {
          clientConnection.close();
          clientEndDone.complete(null);
        });
      if (toClose == "client") {
        clientConnection.close();
      }
    });
  });
}

void testCloseBothEnds() {
  ReceivePort port = new ReceivePort();
  SecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
    var clientEndFuture = SecureSocket.connect(HOST_NAME, server.port);
    server.listen((serverEnd) {
      clientEndFuture.then((clientEnd) {
        clientEnd.destroy();
        serverEnd.destroy();
        server.close();
        port.close();
      });
    });
  });
}

testPauseServerSocket() {
  const int socketCount = 10;
  var acceptCount = 0;
  var resumed = false;

  ReceivePort port = new ReceivePort();

  SecureServerSocket.bind(SERVER_ADDRESS,
                          0,
                          2 * socketCount,
                          CERTIFICATE).then((server) {
    Expect.isTrue(server.port > 0);
    var subscription;
    subscription = server.listen((connection) {
      Expect.isTrue(resumed);
      connection.close();
      if (++acceptCount == 2 * socketCount) {
        server.close();
        port.close();
      }
    });

    // Pause the server socket subscription and resume it after having
    // connected a number client sockets. Then connect more client
    // sockets.
    subscription.pause();
    var connectCount = 0;
    for (int i = 0; i < socketCount; i++) {
      SecureSocket.connect(HOST_NAME, server.port).then((connection) {
        connection.close();
      });
    }
    new Timer(const Duration(milliseconds: 500), () {
      subscription.resume();
      resumed = true;
      for (int i = 0; i < socketCount; i++) {
        SecureSocket.connect(HOST_NAME, server.port).then((connection) {
          connection.close();
        });
      }
    });
  });
}


testCloseServer() {
  const int socketCount = 3;
  var endCount = 0;
  ReceivePort port = new ReceivePort();
  List ends = [];

  SecureServerSocket.bind(SERVER_ADDRESS, 0, 15, CERTIFICATE).then((server) {
    Expect.isTrue(server.port > 0);
    void checkDone() {
      if (ends.length < 2 * socketCount) return;
      for (var end in ends) {
        end.destroy();
      }
      server.close();
      port.close();
    }

    server.listen((connection) {
      ends.add(connection);
      checkDone();
    });

    for (int i = 0; i < socketCount; i++) {
      SecureSocket.connect(HOST_NAME, server.port).then((connection) {
        ends.add(connection);
        checkDone();
      });
    }
  });
}


main() {
  Path scriptDir = new Path(new Options().script).directoryPath;
  Path certificateDatabase = scriptDir.append('pkcert');
  SecureSocket.initialize(database: certificateDatabase.toNativePath(),
                          password: 'dartdart',
                          useBuiltinRoots: false);

  testCloseOneEnd("client");
  testCloseOneEnd("server");
  testCloseBothEnds();
  testPauseServerSocket();
  testCloseServer();
  // TODO(whesse): Add testPauseSocket from raw_socket_test.dart.
  // TODO(whesse): Add testCancelResubscribeSocket from raw_socket_test.dart.
}
