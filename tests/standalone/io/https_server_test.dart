// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
import "dart:async";
import "dart:io";
import "dart:uri";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

void testListenOn() {
  void test(void onDone()) {
    HttpServer.bindSecure(SERVER_ADDRESS,
                          0,
                          backlog: 5,
                          certificateName: 'localhost_cert').then((server) {
      ReceivePort serverPort = new ReceivePort();
      server.listen((HttpRequest request) {
        request.listen(
          (_) { },
          onDone: () {
            request.response.close();
            serverPort.close();
          });
      });

      HttpClient client = new HttpClient();
      ReceivePort clientPort = new ReceivePort();
      client.getUrl(Uri.parse("https://$HOST_NAME:${server.port}/"))
        .then((HttpClientRequest request) {
          return request.close();
        })
        .then((HttpClientResponse response) {
            response.listen(
              (_) { },
              onDone: () {
                client.close();
                clientPort.close();
                server.close();
                Expect.throws(() => server.port);
                onDone();
              });
        })
        .catchError((e) {
          String msg = "Unexpected error in Https client: $e";
          var trace = getAttachedStackTrace(e);
          if (trace != null) msg += "\nStackTrace: $trace";
          Expect.fail(msg);
        });
    });
  }

  // Test two servers in succession.
  test(() {
    test(() { });
  });
}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.initialize(database: testPkcertDatabase.toNativePath(),
                          password: 'dartdart');
}

void main() {
  InitializeSSL();
  testListenOn();
}
