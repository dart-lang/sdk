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
import "dart:isolate";
import "package:expect/expect.dart";
import "package:path/path.dart";

String localFile(path) => Platform.script.resolve(path).toFilePath();

final SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

final SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

main() async {
  List<int> message = "GET / HTTP/1.0\r\nHost: localhost\r\n\r\n".codeUnits;
  int written = 0;
  List<int> body = <int>[];
  var server =
      await HttpServer.bindSecure("localhost", 0, serverContext, backlog: 5);
  server.listen((HttpRequest request) async {
    await request.drain();
    request.response.contentLength = 100;
    for (int i = 0; i < 10; i++) {
      request.response.add([0, 1, 2, 3, 4, 5, 6, 7, 8, 9]);
    }
    request.response.close();
  });
  var socket = await RawSecureSocket.connect("localhost", server.port,
      context: clientContext);
  socket.listen((RawSocketEvent event) {
    switch (event) {
      case RawSocketEvent.READ:
        body.addAll(socket.read());
        break;
      case RawSocketEvent.WRITE:
        written += socket.write(message, written, message.length - written);
        if (written < message.length) {
          socket.writeEventsEnabled = true;
        } else {
          socket.shutdown(SocketDirection.SEND);
        }
        break;
      case RawSocketEvent.READ_CLOSED:
        Expect.isTrue(body.length > 100, "$body\n${body.length}");
        Expect.equals(72, body[0]);
        Expect.equals(9, body[body.length - 1]);
        server.close();
        break;
      default:
        throw "Unexpected event $event";
    }
  }, onError: (e, trace) {
    String msg = "onError handler of RawSecureSocket stream hit $e";
    if (trace != null) msg += "\nStackTrace: $trace";
    Expect.fail(msg);
  });
}
