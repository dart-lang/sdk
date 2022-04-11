// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
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
//
// It is not possible to initiate TLS-renegotiation from a pure-Dart server so
// just test that the `allowLegacyUnsafeRenegotiation` in `SecurityContext`
// does not affect connections that do *not* do renegotiation.

// @dart = 2.9

import "dart:async";
import 'dart:convert';
import "dart:io";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

InternetAddress HOST;

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
  // NOTE: this test only verifies that `allowLegacyUnsafeRenegotiation` does
  // not cause incorrect behavior when enabled - the server does *not* actually
  // trigger TLS renegotiation.
  SecurityContext clientContext = new SecurityContext()
    ..allowLegacyUnsafeRenegotiation = true
    ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

  await SecureSocket.connect(HOST, server.port, context: clientContext)
      .then((socket) async {
    socket.write("Hello server.");
    socket.close();
    Expect.isTrue(await utf8.decoder.bind(socket).contains("Hello server."));
  });
}

testProperty() {
  SecurityContext context = new SecurityContext();
  Expect.isFalse(context.allowLegacyUnsafeRenegotiation);
  context.allowLegacyUnsafeRenegotiation = true;
  Expect.isTrue(context.allowLegacyUnsafeRenegotiation);
  context.allowLegacyUnsafeRenegotiation = false;
  Expect.isFalse(context.allowLegacyUnsafeRenegotiation);
}

void main() async {
  asyncStart();
  await InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first);
  final server = await startEchoServer();

  await testSuccess(server);
  testProperty();

  await server.close();
  asyncEnd();
}
