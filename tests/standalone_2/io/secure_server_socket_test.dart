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

void testSimpleBind() {
  asyncStart();
  SecureServerSocket.bind(HOST, 0, serverContext).then((s) {
    Expect.isTrue(s.port > 0);
    s.close();
    asyncEnd();
  });
}

void testInvalidBind() {
  int count = 0;

  // Bind to a unknown DNS name.
  asyncStart();
  SecureServerSocket.bind("ko.faar.__hest__", 0, serverContext).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to an unavaliable IP-address.
  asyncStart();
  SecureServerSocket.bind("8.8.8.8", 0, serverContext).then((_) {
    Expect.fail("Failure expected");
  }).catchError((error) {
    Expect.isTrue(error is SocketException);
    asyncEnd();
  });

  // Bind to a port already in use.
  asyncStart();
  SecureServerSocket.bind(HOST, 0, serverContext).then((s) {
    SecureServerSocket.bind(HOST, s.port, serverContext).then((t) {
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
  SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    var clientEndFuture =
        SecureSocket.connect(HOST, server.port, context: clientContext);
    server.listen((serverEnd) {
      clientEndFuture.then((clientEnd) {
        var x5 = clientEnd.peerCertificate;
        print(x5.subject);
        print(x5.issuer);
        print(x5.startValidity);
        print(x5.endValidity);
        clientEnd.close();
        serverEnd.close();
        server.close();
        asyncEnd();
      });
    });
  });
}

void testSimpleConnectFail(SecurityContext serverContext,
    SecurityContext clientContext, bool cancelOnError) {
  print('$serverContext $clientContext $cancelOnError');
  asyncStart();
  SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    var clientEndFuture = SecureSocket
        .connect(HOST, server.port, context: clientContext)
        .then((clientEnd) {
      Expect.fail("No client connection expected.");
    }).catchError((error) {
      // TODO(whesse): When null context is supported, disallow
      // the ArgumentError type here.
      Expect.isTrue(error is ArgumentError ||
          error is HandshakeException ||
          error is SocketException);
    });
    server.listen((serverEnd) {
      Expect.fail("No server connection expected.");
    }, onError: (error) {
      // TODO(whesse): When null context is supported, disallow
      // the ArgumentError type here.
      Expect.isTrue(error is ArgumentError ||
          error is HandshakeException ||
          error is SocketException);
      clientEndFuture.then((_) {
        if (!cancelOnError) server.close();
        asyncEnd();
      });
    }, cancelOnError: cancelOnError);
  });
}

void testServerListenAfterConnect() {
  asyncStart();
  SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    Expect.isTrue(server.port > 0);
    var clientEndFuture =
        SecureSocket.connect(HOST, server.port, context: clientContext);
    new Timer(const Duration(milliseconds: 500), () {
      server.listen((serverEnd) {
        clientEndFuture.then((clientEnd) {
          clientEnd.close();
          serverEnd.close();
          server.close();
          asyncEnd();
        });
      });
    });
  });
}

void testSimpleReadWrite() {
  // This test creates a server and a client connects. The client then
  // writes and the server echos. When the server has finished its
  // echo it half-closes. When the client gets the close event is
  // closes fully.
  asyncStart();

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

  SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    server.listen((client) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> data = new List<int>(messageSize);

      client.listen((buffer) {
        Expect.isTrue(bytesWritten == 0);
        data.setRange(bytesRead, bytesRead + buffer.length, buffer);
        bytesRead += buffer.length;
        if (bytesRead == data.length) {
          verifyTestData(data);
          client.add(data);
          client.close();
        }
      }, onDone: () {
        server.close();
      });
    });

    SecureSocket
        .connect(HOST, server.port, context: clientContext)
        .then((socket) {
      int bytesRead = 0;
      int bytesWritten = 0;
      List<int> dataSent = createTestData();
      List<int> dataReceived = new List<int>(dataSent.length);
      socket.add(dataSent);
      socket.close(); // Can also be delayed.
      socket.listen((List<int> buffer) {
        dataReceived.setRange(bytesRead, bytesRead + buffer.length, buffer);
        bytesRead += buffer.length;
      }, onDone: () {
        verifyTestData(dataReceived);
        socket.close();
        asyncEnd();
      });
    });
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
  testSimpleBind();
  testInvalidBind();
  testSimpleConnect();
  for (var server in [serverContext, null]) {
    for (var client in [clientContext, null]) {
      for (bool cancelOnError in [true, false]) {
        if (server == null || client == null) {
          testSimpleConnectFail(server, client, cancelOnError);
        }
      }
    }
  }
  testServerListenAfterConnect();
  testSimpleReadWrite();
}
