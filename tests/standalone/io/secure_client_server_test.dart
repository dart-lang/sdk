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

late InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

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

void checkServerCertificate(X509Certificate serverCert) {
  String serverCertString = serverCert.pem;
  String certFile =
      new File(localFile('certificates/server_chain.pem')).readAsStringSync();
  Expect.isTrue(certFile.contains(serverCertString));

  // Computed with:
  // openssl x509 -noout -sha1 -fingerprint -in certificates/server_chain.pem
  List<int> serverSha1 = <int>[
    0xB3, 0x01, 0xCB, 0x7E, 0x6F, 0xEF, 0xBE, 0xEF, //
    0x75, 0x6D, 0xA8, 0x80, 0x60, 0xA8, 0x5D, 0x6F, //
    0xC4, 0xED, 0xCD, 0x48, //
  ];
  Expect.listEquals(serverSha1, serverCert.sha1);
}

Future testClient(server) {
  return SecureSocket.connect(HOST, server.port, context: clientContext)
      .then((socket) {
    checkServerCertificate(socket.peerCertificate!);
    socket.write("Hello server.");
    socket.close();
    return socket.fold<List<int>>(
        <int>[], (message, data) => message..addAll(data)).then((message) {
      Expect.listEquals("Hello server.".codeUnits, message);
      return server;
    });
  });
}

void main() {
  asyncStart();
  InternetAddress.lookup("localhost")
      .then((hosts) => HOST = hosts.first)
      .then((_) => startEchoServer())
      .then(testClient)
      .then((server) => server.close())
      .then((_) => asyncEnd());
}
