// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=
// VMOptions=--short_socket_read
// VMOptions=--short_socket_write
// VMOptions=--short_socket_read --short_socket_write
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "dart:async";
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;
String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

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
  RawSecureServerSocket.bind(HOST, 0, serverContext).then((server) {
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
    RawSecureSocket
        .connect(HOST, server.port, context: clientContext)
        .then((clientConnection) {
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

void testCloseBothEnds() {
  asyncStart();
  RawSecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    var clientEndFuture =
        RawSecureSocket.connect(HOST, server.port, context: clientContext);
    server.listen((serverEnd) {
      clientEndFuture.then((clientEnd) {
        clientEnd.close();
        serverEnd.close();
        server.close();
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

  RawSecureServerSocket
      .bind(HOST, 0, serverContext, backlog: 2 * socketCount)
      .then((server) {
    Expect.isTrue(server.port > 0);
    var subscription;
    subscription = server.listen((connection) {
      Expect.isTrue(resumed);
      connection.shutdown(SocketDirection.SEND);
      if (++acceptCount == 2 * socketCount) {
        server.close();
        asyncEnd();
      }
    });

    // Pause the server socket subscription and resume it after having
    // connected a number client sockets. Then connect more client
    // sockets.
    subscription.pause();
    var connectCount = 0;
    for (int i = 0; i < socketCount; i++) {
      RawSecureSocket
          .connect(HOST, server.port, context: clientContext)
          .then((connection) {
        connection.shutdown(SocketDirection.SEND);
      });
    }
    new Timer(const Duration(milliseconds: 500), () {
      subscription.resume();
      resumed = true;
      for (int i = 0; i < socketCount; i++) {
        RawSecureSocket
            .connect(HOST, server.port, context: clientContext)
            .then((connection) {
          connection.shutdown(SocketDirection.SEND);
        });
      }
    });
  });
}

testCloseServer() {
  const int socketCount = 3;
  asyncStart();
  List ends = [];

  RawSecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    Expect.isTrue(server.port > 0);
    void checkDone() {
      if (ends.length < 2 * socketCount) return;
      for (var end in ends) {
        end.close();
      }
      server.close();
      asyncEnd();
    }

    server.listen((connection) {
      ends.add(connection);
      checkDone();
    });

    for (int i = 0; i < socketCount; i++) {
      RawSecureSocket
          .connect(HOST, server.port, context: clientContext)
          .then((connection) {
        ends.add(connection);
        checkDone();
      });
    }
  });
}

main() {
  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) {
    HOST = hosts.first;
    runTests();
    asyncEnd();
  });
}

runTests() {
  testCloseOneEnd("client");
  testCloseOneEnd("server");
  testCloseBothEnds();
  testCloseServer();
  testPauseServerSocket();
  // TODO(whesse): Add testPauseSocket from raw_socket_test.dart.
  // TODO(whesse): Add testCancelResubscribeSocket from raw_socket_test.dart.
}
