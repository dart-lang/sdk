// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
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

late InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

Future<SecureServerSocket> startEchoServer() {
  return SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    server.listen((SecureSocket client) {
      client.fold<List<int>>(
          <int>[], (message, data) => message..addAll(data)).then((message) {
        client.add(message);
        client.close();
      });
    });
    return server;
  });
}

testSuccess(SecureServerSocket server) async {
  var log = "";
  SecurityContext clientContext = new SecurityContext()
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

  await SecureSocket.connect(HOST, server.port, context: clientContext,
      keyLog: (line) {
    log += line;
  }).then((socket) {
    socket.write("Hello server.");
    socket.close();
    return socket.drain().then((value) {
      Expect.contains("CLIENT_HANDSHAKE_TRAFFIC_SECRET", log);
      return server;
    });
  });
}

testExceptionInKeyLogFunction(SecureServerSocket server) async {
  SecurityContext clientContext = new SecurityContext()
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

  var numCalls = 0;
  await SecureSocket.connect(HOST, server.port, context: clientContext,
      keyLog: (line) {
    ++numCalls;
    throw FileSystemException("Something bad happened");
  }).then((socket) {
    socket.close();
    return socket.drain().then((value) {
      Expect.notEquals(0, numCalls);
      return server;
    });
  });
}

void main() async {
  asyncStart();
  await InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first);
  final server = await startEchoServer();

  await testSuccess(server);
  await testExceptionInKeyLogFunction(server);

  await server.close();
  asyncEnd();
}
