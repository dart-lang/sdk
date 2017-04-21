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

library dart.io;

import "dart:async";
import "dart:io";
import "dart:math";
import "dart:typed_data";

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";
import "package:path/path.dart";

part "../../../sdk/lib/io/crypto.dart";

const String webSocketGUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
const String CERT_NAME = 'localhost_cert';
const String HOST_NAME = 'localhost';

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

/**
 * A SecurityConfiguration lets us run the tests over HTTP or HTTPS.
 */
class SecurityConfiguration {
  final bool secure;

  SecurityConfiguration({bool this.secure});

  Future<HttpServer> createServer({int backlog: 0}) => secure
      ? HttpServer.bindSecure(HOST_NAME, 0, serverContext, backlog: backlog)
      : HttpServer.bind(HOST_NAME, 0, backlog: backlog);

  Future<WebSocket> createClient(int port) =>
      // TODO(whesse): Add a client context argument to WebSocket.connect.
      WebSocket.connect('${secure ? "wss" : "ws"}://$HOST_NAME:$port/');

  void testForceCloseServerEnd(int totalConnections) {
    createServer().then((server) {
      server.listen((request) {
        var response = request.response;
        response.statusCode = HttpStatus.SWITCHING_PROTOCOLS;
        response.headers.set(HttpHeaders.CONNECTION, "upgrade");
        response.headers.set(HttpHeaders.UPGRADE, "websocket");
        String key = request.headers.value("Sec-WebSocket-Key");
        _SHA1 sha1 = new _SHA1();
        sha1.add("$key$webSocketGUID".codeUnits);
        String accept = _CryptoUtils.bytesToBase64(sha1.close());
        response.headers.add("Sec-WebSocket-Accept", accept);
        response.headers.contentLength = 0;
        response.detachSocket().then((socket) {
          socket.destroy();
        });
      });

      int closeCount = 0;
      for (int i = 0; i < totalConnections; i++) {
        createClient(server.port).then((webSocket) {
          webSocket.add("Hello, world!");
          webSocket.listen((message) {
            Expect.fail("unexpected message");
          }, onDone: () {
            closeCount++;
            if (closeCount == totalConnections) {
              server.close();
            }
          });
        });
      }
    });
  }

  void runTests() {
    testForceCloseServerEnd(10);
  }
}

main() {
  asyncStart();
  new SecurityConfiguration(secure: false).runTests();
  // TODO(whesse): WebSocket.connect needs an optional context: parameter
  // new SecurityConfiguration(secure: true).runTests();
  asyncEnd();
}
