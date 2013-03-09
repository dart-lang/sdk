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
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
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
    onDone: () {
      serverDone.complete(null);
    });
    RawSecureSocket.connect(HOST_NAME, server.port).then((clientConnection) {
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

void testCloseBothEnds() {
  ReceivePort port = new ReceivePort();
  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 5, CERTIFICATE).then((server) {
    var clientEndFuture = RawSecureSocket.connect(HOST_NAME, server.port);
    server.listen((serverEnd) {
      clientEndFuture.then((clientEnd) {
        clientEnd.close();
        serverEnd.close();
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

  RawSecureServerSocket.bind(SERVER_ADDRESS,
                             0,
                             2 * socketCount,
                             CERTIFICATE).then((server) {
    Expect.isTrue(server.port > 0);
    var subscription;
    subscription = server.listen((connection) {
      Expect.isTrue(resumed);
      connection.shutdown(SocketDirection.SEND);
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
      RawSecureSocket.connect(HOST_NAME, server.port).then((connection) {
        connection.shutdown(SocketDirection.SEND);
      });
    }
    new Timer(const Duration(milliseconds: 500), () {
      subscription.resume();
      resumed = true;
      for (int i = 0; i < socketCount; i++) {
        RawSecureSocket.connect(HOST_NAME, server.port).then((connection) {
          connection.shutdown(SocketDirection.SEND);
        });
      }
    });
  });
}

testCloseServer() {
  const int socketCount = 3;
  ReceivePort port = new ReceivePort();
  List ends = [];

  RawSecureServerSocket.bind(SERVER_ADDRESS, 0, 15, CERTIFICATE).then((server) {
    Expect.isTrue(server.port > 0);
    void checkDone() {
      if (ends.length < 2 * socketCount) return;
      for (var end in ends) {
        end.close();
      }
      server.close();
      port.close();
    }

    server.listen((connection) {
      ends.add(connection);
      checkDone();
    });

    for (int i = 0; i < socketCount; i++) {
      RawSecureSocket.connect(HOST_NAME, server.port).then((connection) {
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
  testCloseServer();
  testPauseServerSocket();
  // TODO(whesse): Add testPauseSocket from raw_socket_test.dart.
  // TODO(whesse): Add testCancelResubscribeSocket from raw_socket_test.dart.
}
