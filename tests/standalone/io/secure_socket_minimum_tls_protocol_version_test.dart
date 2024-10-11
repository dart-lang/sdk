// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem
//
// This test does not verify that the value set in `minimumTlsProtocolVersion`
// appears in the supported versions extension as defined in RPC-8446 4.2.1.
import "dart:async";
import 'dart:convert';
import "dart:io";

import "package:expect/async_helper.dart";
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

testVersion(SecureServerSocket server, TlsProtocolVersion tlsVersion) async {
  // NOTE: this test only verifies that `minimumTlsProtocolVersion` does
  // not cause incorrect behavior when used - the server does *not* actually
  // verify that the supported versions extension is correctly set.
  SecurityContext clientContext = new SecurityContext()
    ..minimumTlsProtocolVersion = tlsVersion
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
  Expect.equals(TlsProtocolVersion.tls1_2, context.minimumTlsProtocolVersion);
  context.minimumTlsProtocolVersion = TlsProtocolVersion.tls1_3;
  Expect.equals(TlsProtocolVersion.tls1_3, context.minimumTlsProtocolVersion);
}

void main() async {
  asyncStart();
  await InternetAddress.lookup("localhost").then((hosts) => HOST = hosts.first);
  final server = await startEchoServer();

  testProperty();
  await testVersion(server, TlsProtocolVersion.tls1_2);
  await testVersion(server, TlsProtocolVersion.tls1_3);

  await server.close();
  asyncEnd();
}
