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
SecureServerSocket SERVER;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

Future startServer() {
  return SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    SERVER = server;
    SERVER.listen((SecureSocket client) {
      client.fold(<int>[], (message, data) => message..addAll(data)).then(
          (message) {
        String received = new String.fromCharCodes(message);
        Expect.isTrue(received.contains("Hello from client "));
        String name = received.substring(received.indexOf("client ") + 7);
        client.add("Welcome, client $name".codeUnits);
        client.close();
      });
    });
  });
}

Future testClient(name) {
  return SecureSocket
      .connect(HOST, SERVER.port, context: clientContext)
      .then((socket) {
    socket.add("Hello from client $name".codeUnits);
    socket.close();
    return socket.fold(<int>[], (message, data) => message..addAll(data)).then(
        (message) {
      Expect.listEquals("Welcome, client $name".codeUnits, message);
    });
  });
}

void main() {
  asyncStart();
  InternetAddress
      .lookup("localhost")
      .then((hosts) => HOST = hosts.first)
      .then((_) => startServer())
      .then((_) => ['ale', 'bar', 'che', 'den', 'els'].map(testClient))
      .then((futures) => Future.wait(futures))
      .then((_) => SERVER.close())
      .then((_) => asyncEnd());
}
