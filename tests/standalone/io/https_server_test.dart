// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:io";
import "dart:uri";
import "dart:isolate";

const SERVER_ADDRESS = "127.0.0.1";
const HOST_NAME = "localhost";

void testListenOn() {
  void test(void onDone()) {
    HttpsServer server = new HttpsServer();
    Expect.throws(() => server.port);

    ReceivePort serverPort = new ReceivePort();
    server.defaultRequestHandler =
        (HttpRequest request, HttpResponse response) {
          request.inputStream.onClosed = () {
            response.outputStream.close();
            serverPort.close();
          };
        };

    server.onError = (Exception e) {
      Expect.fail("Unexpected error in Https Server: $e");
    };

    server.listen(SERVER_ADDRESS,
                  0,
                  backlog: 5,
                  certificate_name: 'CN=$HOST_NAME');

    HttpClient client = new HttpClient();
    HttpClientConnection conn =
        client.getUrl(new Uri.fromString("https://$HOST_NAME:${server.port}/"));
    conn.onRequest = (HttpClientRequest request) {
      request.outputStream.close();
    };
    ReceivePort clientPort = new ReceivePort();
    conn.onResponse = (HttpClientResponse response) {
      response.inputStream.onClosed = () {
        client.shutdown();
        clientPort.close();
        server.close();
        Expect.throws(() => server.port);
        onDone();
      };
    };
    conn.onError = (Exception e) {
      Expect.fail("Unexpected error in Https Client: $e");
    };
  };

  // Test two connection after each other.
  test(() {
    test(() {
    });
  });
}

void InitializeSSL() {
  var testPkcertDatabase =
      new Path.fromNative(new Options().script).directoryPath.append('pkcert/');
  SecureSocket.setCertificateDatabase(testPkcertDatabase.toNativePath(),
                                      'dartdart');
}

void main() {
  InitializeSSL();
  testListenOn();
}
