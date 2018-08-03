// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// OtherResources=certificates/server_chain.pem
// OtherResources=certificates/server_key.pem
// OtherResources=certificates/trusted_certs.pem

import "dart:async";
import "dart:io";
import "dart:isolate";

import "package:expect/expect.dart";

InternetAddress HOST;

String localFile(path) => Platform.script.resolve(path).toFilePath();

SecurityContext serverContext = new SecurityContext()
  ..useCertificateChain(localFile('certificates/server_chain.pem'))
  ..usePrivateKey(localFile('certificates/server_key.pem'),
      password: 'dartdart');

SecurityContext clientContext = new SecurityContext()
  ..setTrustedCertificates(localFile('certificates/trusted_certs.pem'));

void testListenOn() {
  void test(void onDone()) {
    HttpServer.bindSecure(HOST, 0, serverContext, backlog: 5).then((server) {
      ReceivePort serverPort = new ReceivePort();
      server.listen((HttpRequest request) {
        request.listen((_) {}, onDone: () {
          request.response.close();
          serverPort.close();
        });
      });

      HttpClient client = new HttpClient(context: clientContext);
      ReceivePort clientPort = new ReceivePort();
      client
          .getUrl(Uri.parse("https://${HOST.host}:${server.port}/"))
          .then((HttpClientRequest request) {
        return request.close();
      }).then((HttpClientResponse response) {
        response.listen((_) {}, onDone: () {
          client.close();
          clientPort.close();
          server.close();
          Expect.throws(() => server.port);
          onDone();
        });
      }).catchError((e, trace) {
        String msg = "Unexpected error in Https client: $e";
        if (trace != null) msg += "\nStackTrace: $trace";
        Expect.fail(msg);
      });
    });
  }

  // Test two servers in succession.
  test(() {
    test(() {});
  });
}

void testEarlyClientClose() {
  HttpServer.bindSecure(HOST, 0, serverContext).then((server) {
    server.listen((request) {
      String name = Platform.script.toFilePath();
      new File(name)
          .openRead()
          .pipe(request.response)
          .catchError((e) {/* ignore */});
    });

    var count = 0;
    makeRequest() {
      Socket.connect(HOST, server.port).then((socket) {
        var data = "Invalid TLS handshake";
        socket.write(data);
        socket.close();
        socket.done.then((_) {
          socket.destroy();
          if (++count < 10) {
            makeRequest();
          } else {
            server.close();
          }
        });
      });
    }

    makeRequest();
  });
}

void main() {
  InternetAddress.lookup("localhost").then((hosts) {
    HOST = hosts.first;
    testListenOn();
    testEarlyClientClose();
  });
}
