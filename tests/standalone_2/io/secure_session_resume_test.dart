// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// This test tests TLS session resume, by making multiple client connections
// on the same port to the same server, with a delay of 200 ms between them.
// The unmodified secure_server_test creates all sessions simultaneously,
// which means that no handshake completes and caches its keys in the session
// cache in time for other connections to use it.
//
// Session resume is currently disabled - see issue
// https://code.google.com/p/dart/issues/detail?id=7230
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
import "dart:isolate";

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

Future<SecureServerSocket> startServer() {
  return SecureServerSocket.bind(HOST, 0, serverContext).then((server) {
    server.listen((SecureSocket client) {
      client.fold(<int>[], (message, data) => message..addAll(data)).then(
          (message) {
        String received = new String.fromCharCodes(message);
        Expect.isTrue(received.contains("Hello from client "));
        String name = received.substring(received.indexOf("client ") + 7);
        client.write("Welcome, client $name");
        client.close();
      });
    });
    return server;
  });
}

Future testClient(server, name) {
  return SecureSocket
      .connect(HOST, server.port, context: clientContext)
      .then((socket) {
    socket.write("Hello from client $name");
    socket.close();
    return socket.fold(<int>[], (message, data) => message..addAll(data)).then(
        (message) {
      Expect.listEquals("Welcome, client $name".codeUnits, message);
      return server;
    });
  });
}

void main() {
  asyncStart();
  InternetAddress.lookup("localhost").then((hosts) {
    HOST = hosts.first;
    runTests().then((_) => asyncEnd());
  });
}

Future runTests() {
  Duration delay = const Duration(milliseconds: 0);
  Duration delay_between_connections = const Duration(milliseconds: 300);
  return startServer()
      .then((server) => Future
              .wait(['able', 'baker', 'charlie', 'dozen', 'elapse'].map((name) {
            delay += delay_between_connections;
            return new Future.delayed(delay, () => server)
                .then((server) => testClient(server, name));
          })))
      .then((servers) => servers.first.close());
}
